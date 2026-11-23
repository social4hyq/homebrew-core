class CmuxProbe < Formula
  desc "P0 probe HAP: ArkTS Web + XComponent side-by-side (cmux-like OHOS)"
  homepage "https://github.com/manaflow-ai/cmux"
  # url/sha256 satisfy brew audit; the probe HAP itself is built from the
  # tap's Resources (this upstream tarball is not used by install), same
  # pattern as herdr-app.
  url "https://github.com/manaflow-ai/cmux/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "3f665dc6d7bb2d09057457721fbd6584906bf00c95732d3cb3e5c4f3392a4608"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/manaflow-ai/cmux.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  # 探针 HAP 源码随 tap 分发（纯 ArkTS，无 upstream tarball）。
  depends_on "node" => :build # hvigorw.js is a node script
  depends_on "app-installer"

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/cmux-probe-hap"
    odie "missing tap resource: Resources/cmux-probe-hap" unless res.exist?

    # HAP 只在 electron-ohos-ci 私有镜像里构建（proprietary CLT）。
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "cmux-probe builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['cmux-probe']"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    hap = buildpath/"hap"
    cp_r res/"hap", hap
    cd hap do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install hap/"entry/build/default/outputs/default/entry-default-unsigned.hap" =>
                    "cmux-probe-unsigned.hap"
    (bin/"cmux-probe").write <<~SH
      #!/bin/sh
      exec "#{formula_opt_bin("app-installer")}" install \\
        --hap "#{libexec}/cmux-probe-unsigned.hap" \\
        --bundle-id com.social4hyq.cmuxprobe \\
        --app-name "cmux probe" --module entry --ability EntryAbility "$@"
    SH
    chmod 0755, bin/"cmux-probe"
  end

  # HAP apps must auto-install via hap-app (hap-checks requirement); the probe
  # HAP is signed with a local debug profile and installed over hdc.
  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "cmux-probe", "com.social4hyq.cmuxprobe"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    hap = libexec/"cmux-probe-unsigned.hap"
    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "entry", manifest.dig("module", "name")
    assert_equal "com.social4hyq.cmuxprobe", manifest.dig("app", "bundleName")
    # 验证探针的两个关键组件都在 ArkTS 源码里。
    index = (Pathname(__FILE__).expand_path.dirname.parent.parent/
             "Resources/cmux-probe-hap/hap/entry/src/main/ets/pages/Index.ets").read
    assert_match "Web({", index
    assert_match "XComponent({", index
    assert_match "setWebDebuggingAccess(true)", index
  end
end
