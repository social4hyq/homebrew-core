class DeepseekHarnessApp < Formula
  desc "Desktop shell for the DeepSeek Harness agent (Electron window on local dsh web)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/refs/tags/dsh-v0.2.3-alpha.2.tar.gz"
  sha256 "e3ae29a992f19f85294806e95b1bc0fef750ca23ce06b2d88944b4bc2a2b3064"
  license :cannot_represent

  livecheck do
    url "https://github.com/deepseek-ai/deepseek-harness.git"
    regex(/^dsh-v(\d+\.\d+\.\d+(?:-(?:alpha|rc)\.\d+)?)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-app-v0.2.3-alpha.2-r4"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92e7db0a2f30baca7efa98447b6e002f162e3fa33d08aa2fd4181a9fb2ad2713"
  end

  depends_on "app-installer"
  depends_on "coreutils"
  depends_on "curl"
  depends_on "deepseek-harness"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "util-linux"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/_shared/waiting-page/render-waiting.cjs
    Resources/_shared/waiting-page/waiting.html.in
    Resources/deepseek-harness-app/app/config.json
    Resources/deepseek-harness-app/app/main.cjs
    Resources/deepseek-harness-app/app/package.json
    Resources/deepseek-harness-app/app/proxy-preload.cjs
    Resources/deepseek-harness-app/app/proxy.cjs
    Resources/deepseek-harness-app/app/startup.cjs
    Resources/deepseek-harness-app/app/tray.cjs
    Resources/deepseek-harness-app/app/waiting.json
    Resources/deepseek-harness-app/assets/icon.png
    Resources/deepseek-harness-app/assets/tray-icon.png
    Resources/deepseek-harness-app/scripts/deepseek-harness-desktop.sh
    Resources/deepseek-harness-app/scripts/install-desktop.sh
    Resources/deepseek-harness-app/tests/close-handler.test.cjs
    Resources/deepseek-harness-app/tests/test-proxy.cjs
    Resources/deepseek-harness-app/tests/test-server-detach.rb
    Resources/deepseek-harness-app/tests/test-startup.cjs
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/deepseek-harness-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp res/"app/main.cjs", app
    cp res/"app/proxy-preload.cjs", app
    cp res/"app/proxy.cjs", app
    cp res/"app/startup.cjs", app
    cp res/"app/tray.cjs", app
    cp res/"app/package.json", app
    cp res/"app/config.json", app
    system "node", tap_root/"Resources/_shared/waiting-page/render-waiting.cjs",
           tap_root/"Resources/_shared/waiting-page/waiting.html.in",
           res/"app/waiting.json", app/"waiting.html"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.deepseekharness"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "DeepSeek Harness"
        end
      end
      File.write(file.to_s, JSON.pretty_generate(strings) + "\n")
    end

    inreplace shell/"build-profile.json5", /[ \t]*"signingConfig": "default",[ \t]*\r?\n/, ""
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    # windowStageClose hides the ability and returns true, which tells the system
    # not to close the window, so the window goes to the tray. Returning false let
    # the system close it right after the hide: the ability's session was destroyed
    # and the whole app was killed and relaunched. The tray quit calls app.exit()
    # to bypass this handler.
    close_handler = [
      "    super.onWindowStageCreate(windowStage);",
      "    try {",
      "      windowStage.on('windowStageClose', () => {",
      "        if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {",
      "          return false;",
      "        }",
      "        const widgetId = Number(this.xcomponentId.substring(ConfigData.WINDOW_PREFIX.length));",
      "        Inject.getOrCreate(AppWindowAdapter).hideWindow(widgetId);",
      "        return true;",
      "      });",
      "    } catch (exception) {",
      "      LogUtil.error(TAG, 'Failed to register window close handler: ' + JSON.stringify(exception));",
      "    }",
      "",
    ].join("\n")
    inreplace shell/"web_engine/src/main/ets/ability/WebAbility.ets",
              "    super.onWindowStageCreate(windowStage);\n", close_handler

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "deepseek-harness-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "deepseek-harness-desktop-unsigned.hap"

    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"deepseek-harness-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    # READ_PASTEBOARD is required for pasting into the shell.
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    (pkgshare/"install-desktop.sh").write(
      (res/"scripts/install-desktop.sh").read,
    )
    chmod 0755, pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    (libexec/"deepseek-harness-desktop.sh").write(
      (res/"scripts/deepseek-harness-desktop.sh").read,
    )
    chmod 0755, libexec/"deepseek-harness-desktop.sh"
    (bin/"deepseek-harness-app").write_env_script opt_libexec/"deepseek-harness-desktop.sh",
      DSH_DESKTOP_UNSIGNED_HAP:   opt_libexec/"deepseek-harness-desktop-unsigned.hap",
      DSH_DESKTOP_INSTALL_SCRIPT: opt_pkgshare/"install-desktop.sh",
      DSH_DESKTOP_MODULE_ACL:     opt_pkgshare/"module-acl.json",
      DSH_DESKTOP_DSH_BIN:        formula_opt_bin("deepseek-harness")/"dsh",
      DSH_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      DSH_DESKTOP_VERSION:        version.to_s,
      PATH:                       "#{formula_opt_bin("node")}:#{formula_opt_bin("deepseek-harness")}:$PATH"
    pkgshare.mkpath
    cp res/"tests/test-startup.cjs", pkgshare/"test-startup.cjs"
    cp res/"tests/test-proxy.cjs", pkgshare/"test-proxy.cjs"
    cp res/"tests/test-server-detach.rb", pkgshare/"test-server-detach.rb"
    bin.install_symlink bin/"deepseek-harness-app" => "dsh-app"
    bin.install_symlink bin/"deepseek-harness-app" => "deepseek-harness-desktop"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "deepseek-harness-app", "com.social4hyq.deepseekharness"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    ENV["HOME"] = testpath/"home"
    %w[deepseek-harness-app dsh-app deepseek-harness-desktop].each do |command|
      assert_match "Usage: deepseek-harness-app", shell_output("#{bin}/#{command} --help")
    end
    assert_predicate bin/"dsh-app", :symlink?
    assert_predicate bin/"deepseek-harness-desktop", :symlink?

    fake_bin = testpath/"bin"
    fake_bin.mkpath
    injected_copy = testpath/"injected.hap"
    installer_args = testpath/"hap-installer-args"

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --signed-hap) echo signed > "$2"; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_installer
    fake_hdc = fake_bin/"hdc"
    fake_hdc.write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_hdc

    ENV.prepend_path "PATH", fake_bin
    ENV.prepend_path "PATH", formula_opt_bin("node").to_s
    ENV["DSH_DESKTOP_HDC"] = (fake_bin/"hdc").to_s
    ENV["DSH_DESKTOP_INSTALLER"] = fake_installer.to_s

    assert_match "installed", shell_output("#{bin}/deepseek-harness-app install")
    config = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
    assert_operator config.fetch("port"), :>, 0
    refute_empty config.fetch("dsh")
    assert_equal Dir.home, config.dig("host", "home")
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = acl_module.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.deepseekharness", installer[installer.index("--bundle-id") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal (fake_bin/"hdc").to_s, installer[installer.index("--hdc") + 1]
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    assert_match "installed", shell_output("#{bin}/deepseek-harness-app install --device chosen")
    installer = installer_args.read.lines(chomp: true)
    assert_equal "chosen", installer[installer.index("--device") + 1]
    assert_match "strong-sandbox", shell_output("#{bin}/deepseek-harness-app install --no-acl")
    strong = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 strong.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }.sort
    keep_tmp = testpath/"keep"
    keep_tmp.mkpath
    kept_output = with_env(TMPDIR: keep_tmp.to_s) do
      shell_output("#{bin}/deepseek-harness-app install --keep 2>&1")
    end
    assert_match "installed (com.social4hyq.deepseekharness, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists keep_tmp/"deepseek-harness-app-signed.hap"

    assert_match(/serving at|already healthy/, shell_output("#{bin}/deepseek-harness-app serve"))
    assert_match "healthy", shell_output("#{bin}/deepseek-harness-app status")
    assert_match "stopped", shell_output("#{bin}/deepseek-harness-app stop")

    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match(/serving at|already healthy/, shell_output("#{bin}/deepseek-harness-app start --serve-only"))
    assert_match "opened", shell_output("#{bin}/deepseek-harness-app start")
    assert_match "healthy", shell_output("#{bin}/deepseek-harness-app status")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.deepseekharness -m electron],
                 serve_only_args.read.lines(chomp: true)
    assert_match "stopped", shell_output("#{bin}/deepseek-harness-app stop")

    assert_match "opened", shell_output("#{bin}/deepseek-harness-app start")
    assert_match "healthy", shell_output("#{bin}/deepseek-harness-app status")
    assert_match "stopped", shell_output("#{bin}/deepseek-harness-app stop")

    # uninstall goes through app-installer and keeps the app's data unless
    # --purge is given; --device/HDC_TARGET pick the hdc target.
    shell_output("#{bin}/deepseek-harness-app uninstall --purge --device tablet-1")
    assert_equal %w[uninstall --bundle-id com.social4hyq.deepseekharness --device tablet-1 --purge],
                 installer_args.read.lines(chomp: true)
    shell_output("#{bin}/deepseek-harness-app uninstall")
    assert_equal %w[uninstall --bundle-id com.social4hyq.deepseekharness], installer_args.read.lines(chomp: true)
    with_env("HDC_TARGET" => "env-device") do
      shell_output("#{bin}/deepseek-harness-app uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.deepseekharness --device env-device],
                 installer_args.read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/deepseek-harness-app --help")

    hap = libexec/"deepseek-harness-desktop-unsigned.hap"
    assert_match "libs/arm64-v8a/libelectron.so", shell_output("unzip -Z1 #{hap}")
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "node", "--test", tap_root/"Resources/deepseek-harness-app/tests/close-handler.test.cjs"
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "deepseek-harness-app status", waiting_source
    refute_match "{{", waiting_source
    helper = testpath/"startup.cjs"
    helper.write shell_output("unzip -p #{hap} resources/resfile/resources/app/startup.cjs")
    ENV["DSH_APP_STARTUP_HELPER"] = helper
    system "node", "--test", pkgshare/"test-startup.cjs"
    proxy_helper = testpath/"proxy.cjs"
    proxy_helper.write shell_output("unzip -p #{hap} resources/resfile/resources/app/proxy.cjs")
    ENV["DSH_APP_PROXY_HELPER"] = proxy_helper
    system "node", "--test", pkgshare/"test-proxy.cjs"
    system RbConfig.ruby, pkgshare/"test-server-detach.rb", libexec/"deepseek-harness-desktop.sh"
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package.fetch("version")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.deepseekharness", profile.fetch("app").fetch("bundleName")
    permissions = profile.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
