class DeepseekHarnessApp < Formula
  desc "Desktop shell for the DeepSeek Harness agent (Electron window on local dsh web)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/refs/tags/dsh-v0.2.2-rc.4.tar.gz"
  sha256 "4668e9b8a5f836693c731a808214445f5fce6cfa2956cf47f473e9b6e023f4b3"
  license :cannot_represent

  revision 5

  livecheck do
    url "https://github.com/deepseek-ai/deepseek-harness.git"
    regex(/^dsh-v(\d+\.\d+\.\d+(?:-(?:alpha|rc)\.\d+)?)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-app-v0.2.2-rc.4-r8"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58927eb6f3ec03605b2a9c7ea85d90319bcf4d28e93bd73225262be34b76a85b"
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

  # Shell sources live in the tap so they are reviewable in the PR. Every path
  # is listed literally: the weekly remove-unused-patches job keeps a
  # Resources/ directory only while a formula names it.
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
    Resources/deepseek-harness-app/tests/test-proxy.cjs
    Resources/deepseek-harness-app/tests/test-server-detach.rb
    Resources/deepseek-harness-app/tests/test-startup.cjs
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/deepseek-harness-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

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
    # waiting.html is rendered from the page template shared by the HAP apps and
    # this app's strings. The result is byte for byte the page that used to be
    # kept here; Resources/_shared/waiting-page/expected.sha256 pins it.
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

    # The caption close button never reaches Electron's BrowserWindow close
    # event, and this runtime cannot cancel the close either: the window
    # UIAbility is torn down whatever windowStageClose returns. What keeps the
    # shell (and the dsh web backend it may have started) alive is calling
    # hideAbility() before that teardown -- the platform then recreates the
    # shell as a hidden instance whose tray restores the window. Hiding after
    # the teardown instead makes the app exit, so the call stays synchronous.
    # The tray's quit item calls app.exit() for the same reason.
    close_handler = [
      "    super.onWindowStageCreate(windowStage);",
      "    try {",
      "      windowStage.on('windowStageClose', () => {",
      "        if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {",
      "          return false;",
      "        }",
      "        const widgetId = Number(this.xcomponentId.substring(ConfigData.WINDOW_PREFIX.length));",
      "        Inject.getOrCreate(AppWindowAdapter).hideWindow(widgetId);",
      "        return false;",
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
    if hard_cap > 65_536
      Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536)
    end

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
    # READ_PASTEBOARD makes paste work in the shell; without it pasting into the
    # window does nothing.
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
    # install-desktop.sh sources the install flow shared by the HAP apps from
    # the same directory. cp, not install: the tap checkout is a read-only host
    # mount inside the CI container.
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    (libexec/"deepseek-harness-desktop.sh").write(
      (res/"scripts/deepseek-harness-desktop.sh").read,
    )
    chmod 0755, libexec/"deepseek-harness-desktop.sh"
    (bin/"dsh-app").write_env_script opt_libexec/"deepseek-harness-desktop.sh",
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
    bin.install_symlink bin/"dsh-app" => "deepseek-harness-desktop"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run `dsh-app install`.

      Closing the window hides it to the DeepSeek Harness system tray icon.
      `dsh-app install` and `dsh-app start` start a detached CLI-managed
      `dsh web` backend before opening the shell, so it survives the shell's
      window lifecycle. Use the tray menu to show the window again or to quit.

      The shell needs weak-sandbox ACLs, granted through a local debug profile
      generated by app-installer. They include READ_PASTEBOARD, without which
      pasting into the window does not work.

      The formula follows the deepseek-harness upstream version. If the CLI and
      desktop versions differ, install/start prints a warning but does not stop.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: dsh-app", shell_output("#{bin}/deepseek-harness-desktop --help")
    assert_match "Usage: dsh-app", shell_output("#{bin}/dsh-app --help")

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

    assert_match "installed", shell_output("#{bin}/dsh-app install")
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
    assert_match "installed", shell_output("#{bin}/dsh-app install --device chosen")
    installer = installer_args.read.lines(chomp: true)
    assert_equal "chosen", installer[installer.index("--device") + 1]
    # --no-acl installs the strong-sandbox variant (the HAP's own permissions).
    assert_match "strong-sandbox", shell_output("#{bin}/dsh-app install --no-acl")
    strong = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 strong.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }.sort
    # --keep leaves the signed HAP next to the other temporary files and the
    # result line names the variant that was installed.
    kept_output = shell_output("#{bin}/dsh-app install --keep 2>&1")
    assert_match "installed (com.social4hyq.deepseekharness, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists Pathname(ENV.fetch("TMPDIR", "/tmp"))/"deepseek-harness-app-signed.hap"

    assert_match(/serving at|already healthy/, shell_output("#{bin}/dsh-app serve"))
    assert_match "healthy", shell_output("#{bin}/dsh-app status")
    assert_match "stopped", shell_output("#{bin}/dsh-app stop")

    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match(/serving at|already healthy/, shell_output("#{bin}/dsh-app start --serve-only"))
    assert_match "opened", shell_output("#{bin}/dsh-app start")
    assert_match "healthy", shell_output("#{bin}/dsh-app status")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.deepseekharness -m electron],
                 serve_only_args.read.lines(chomp: true)
    assert_match "stopped", shell_output("#{bin}/dsh-app stop")

    # `start` also brings the host backend up, so the agent survives the shell.
    assert_match "opened", shell_output("#{bin}/dsh-app start")
    assert_match "healthy", shell_output("#{bin}/dsh-app status")
    assert_match "stopped", shell_output("#{bin}/dsh-app stop")

    hap = libexec/"deepseek-harness-desktop-unsigned.hap"
    assert_path_exists hap
    assert_path_exists pkgshare/"module-acl.json"
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/proxy.cjs", listing
    assert_match "resources/resfile/resources/app/proxy-preload.cjs", listing
    assert_match "resources/resfile/resources/app/tray.cjs", listing
    assert_match "resources/resfile/resources/app/tray-icon.png", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "dsh-app status", waiting_source
    refute_match "{{", waiting_source
    tray_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/tray.cjs")
    assert_match "new Tray(", tray_source
    assert_match "preventDefault", tray_source
    window_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/main.cjs")
    assert_match "tray.create(", window_source
    assert_match "DSH_DESKTOP_NO_TRAY", window_source
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
