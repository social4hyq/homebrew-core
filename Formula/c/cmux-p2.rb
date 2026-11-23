class CmuxP2 < Formula
  desc "P2 skeleton HAP: libghostty-ohos terminal + ArkWeb browser (cmux-like OHOS)"
  homepage "https://github.com/manaflow-ai/cmux"
  # url/sha256 satisfy brew audit; HAP source is built from tap Resources
  # (this tarball is not used by install), same pattern as herdr-app / cmux-probe.
  url "https://github.com/manaflow-ai/cmux/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "3f665dc6d7bb2d09057457721fbd6584906bf00c95732d3cb3e5c4f3392a4608"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/manaflow-ai/cmux.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/cmux-p2-v0.2.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07a04df74a8299b450d3b4b72d5af2dd80c96af90783c93afe308991293ee96d"
  end

  depends_on "node" => :build # hvigorw.js / pm-cli.js are node scripts
  depends_on "app-installer"

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/cmux-p2-hap"
    odie "missing tap resource: Resources/cmux-p2-hap" unless res.exist?

    # HAP builds only inside electron-ohos-ci (proprietary CLT at
    # /opt/electron-ohos-clt); see OHOS_CI_IMAGE_OVERRIDES['cmux-p2'].
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "cmux-p2 builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['cmux-p2']"
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
                    "cmux-p2-unsigned.hap"
    # bin name must end in "-app": hap-app's valid_command regex is
    # ^[a-z][a-z0-9-]*-app$. app-installer is linked into prefix bin;
    # formula_opt_bin() returns its opt prefix (a directory), so use bin/.
    (bin/"cmux-p2-app").write <<~SH
      #!/bin/sh
      exec "#{bin}/app-installer" install \\
        --hap "#{libexec}/cmux-p2-unsigned.hap" \\
        --bundle-id com.social4hyq.cmuxp2 \\
        --app-name cmux_p2 --module entry --ability EntryAbility "$@"
    SH
    chmod 0755, bin/"cmux-p2-app"
  end

  # HAP apps must auto-install via hap-app (hap-checks requirement).
  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "cmux-p2-app", "com.social4hyq.cmuxp2"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    hap = libexec/"cmux-p2-unsigned.hap"
    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "entry", manifest.dig("module", "name")
    assert_equal "com.social4hyq.cmuxp2", manifest.dig("app", "bundleName")
    index = (Pathname(__FILE__).expand_path.dirname.parent.parent/
             "Resources/cmux-p2-hap/hap/entry/src/main/ets/pages/Index.ets").read
    assert_match "TerminalSurface", index
    assert_match "termController", index
    assert_match "Web({", index
    assert_match "setWebDebuggingAccess(true)", index
    ohpkg = (Pathname(__FILE__).expand_path.dirname.parent.parent/
             "Resources/cmux-p2-hap/hap/entry/oh-package.json5").read
    assert_match "libghostty-ohos", ohpkg
  end
end
