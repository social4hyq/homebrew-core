class CmuxApp < Formula
  desc "Cmux-like agent terminal for OHOS with herdr-core bridge"
  homepage "https://github.com/manaflow-ai/cmux"
  url "https://github.com/manaflow-ai/cmux/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "3f665dc6d7bb2d09057457721fbd6584906bf00c95732d3cb3e5c4f3392a4608"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/manaflow-ai/cmux.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  depends_on "node" => :build
  depends_on "app-installer"
  depends_on "herdr-core"
  depends_on "python@3.15"

  RESOURCE_FILES = %w[
    Resources/cmux-app/hap/AppScope/app.json5
    Resources/cmux-app/hap/AppScope/resources/base/element/string.json
    Resources/cmux-app/hap/AppScope/resources/base/media/example_icon.png
    Resources/cmux-app/hap/build-profile.json5
    Resources/cmux-app/hap/entry/build-profile.json5
    Resources/cmux-app/hap/entry/hvigorfile.ts
    Resources/cmux-app/hap/entry/oh-package-lock.json5
    Resources/cmux-app/hap/entry/oh-package.json5
    Resources/cmux-app/hap/entry/src/main/ets/entryability/EntryAbility.ets
    Resources/cmux-app/hap/entry/src/main/ets/pages/Index.ets
    Resources/cmux-app/hap/entry/src/main/ets/bridge/HcBridge.ets
    Resources/cmux-app/hap/entry/src/main/module.json5
    Resources/cmux-app/hap/entry/src/main/resources/base/element/color.json
    Resources/cmux-app/hap/entry/src/main/resources/base/media/example_icon.png
    Resources/cmux-app/hap/entry/src/main/resources/base/profile/main_pages.json
    Resources/cmux-app/hap/entry/src/main/resources/rawfile/probe.html
    Resources/cmux-app/hap/hvigor/hvigor-config.json5
    Resources/cmux-app/hap/hvigorfile.ts
    Resources/cmux-app/hap/oh-package-lock.json5
    Resources/cmux-app/hap/oh-package.json5
    Resources/cmux-app/cmux-app.sh
    Resources/cmux-app/herdr-bridge.py
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/cmux-app"
    odie "missing tap resource: Resources/cmux-app" unless res.exist?
    RESOURCE_FILES.each { |f| odie "missing tap resource: #{f}" unless (tap_root/f).exist? }

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "cmux-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['cmux-app']"
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
                    "cmux-app-unsigned.hap"
    cp res/"cmux-app.sh", libexec/"cmux-app.sh"
    cp res/"herdr-bridge.py", libexec/"herdr-bridge.py"
    chmod 0755, [libexec/"cmux-app.sh", libexec/"herdr-bridge.py"]
    (bin/"cmux-app").write_env_script libexec/"cmux-app.sh",
      CMUX_APP_HAP:    libexec/"cmux-app-unsigned.hap",
      CMUX_APP_HC:     formula_opt_bin("herdr-core")/"hc",
      CMUX_APP_BRIDGE: libexec/"herdr-bridge.py",
      CMUX_APP_PYTHON: formula_opt_bin("python@3.15")/"python3"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "cmux-app", "com.social4hyq.cmuxapp"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    hap = libexec/"cmux-app-unsigned.hap"
    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.cmuxapp", manifest.dig("app", "bundleName")
    assert_equal "entry", manifest.dig("module", "name")
    # The ArkTS sources must wire the hc bridge into the terminal surface.
    index = (Pathname(__FILE__).expand_path.dirname.parent.parent/
             "Resources/cmux-app/hap/entry/src/main/ets/pages/Index.ets").read
    assert_match "HcBridge", index
    assert_match "TerminalSurface", index
    assert_match "terminal.list", index
    bridge = (Pathname(__FILE__).expand_path.dirname.parent.parent/
              "Resources/cmux-app/hap/entry/src/main/ets/bridge/HcBridge.ets").read
    assert_match "terminal.attach", bridge
    assert_match "frame", bridge
  end
end
