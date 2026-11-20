class OpencodeApp < Formula
  desc "Desktop shell for the OpenCode agent (Electron window on local opencode serve)"
  homepage "https://opencode.ai"
  # Version follows the upstream opencode tag; OHOS sources live in
  # Resources/opencode-app.
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "48b0ab7c4732d693c59e0ad7d73656a2965b2def78cef3c6319e444b7e6c0300"
  # Tap-authored shell sources (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent
  revision 14

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    throttle days: 1
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-app-v2.3.0-r15"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db0f44cf8791bfc98ffb4dcc111fc53bfd2121cf7fb7f9e486dd9aaddd4a54d2"
  end

  depends_on "app-installer"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "opencode"
  depends_on "unzip"
  depends_on "zip"

  # List every path literally: the unused-resource audit keeps a Resources/
  # directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/electron-shell/tray.cjs
    Resources/_shared/hap-app/install-lib.sh
    Resources/_shared/waiting-page/render-waiting.cjs
    Resources/_shared/waiting-page/waiting.html.in
    Resources/opencode-app/app/config.json
    Resources/opencode-app/app/main.cjs
    Resources/opencode-app/app/package.json
    Resources/opencode-app/app/waiting.json
    Resources/opencode-app/assets/icon.png
    Resources/opencode-app/assets/tray-icon.png
    Resources/opencode-app/scripts/install-desktop.sh
    Resources/opencode-app/scripts/opencode-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/opencode-app"
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
    %w[main.cjs package.json config.json].each do |name|
      cp res/"app"/name, app/name
    end
    cp tap_root/"Resources/_shared/electron-shell/tray.cjs", app/"tray.cjs"
    # waiting.html is generated from the shared page template;
    # Resources/_shared/waiting-page/expected.sha256 pins the output.
    system "node", tap_root/"Resources/_shared/waiting-page/render-waiting.cjs",
           tap_root/"Resources/_shared/waiting-page/waiting.html.in",
           res/"app/waiting.json", app/"waiting.html"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.opencodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # Patch app name/labels in every locale: the base file alone leaves the
    # zh_CN/en_US overrides showing "Electron".
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "OpenCode"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # Mirror the packaging deltas for the CI image's NDK-less SDK subset
    # (no llvm-strip).
    inreplace shell/"build-profile.json5", /^[ \t]*"signingConfig": "default",\r?\n/, ""
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # Trim ACL-gated permissions local auto-signing cannot grant; the shell
    # only needs loopback HTTP.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    # windowStageClose hides the ability and cancels the close so the window
    # goes to the tray; the tray quit calls app.exit() to bypass that handler.
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

    # The shell builds in the private electron-ohos-ci image
    # (OHOS_CI_IMAGE_OVERRIDES) with the proprietary CLT at
    # /opt/electron-ohos-clt; it compiles no C++, so the NDK-less SDK suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "opencode-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['opencode-app']"
    end

    # brew's sanitized env drops LD_LIBRARY_PATH; restore it for
    # ohos_packing_tool.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # Cap RLIMIT_NOFILE for the hvigor tree: near-1e9 limits break the musl FD
    # table. Only ever lower it.
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
                    "opencode-desktop-unsigned.hap"

    # The ACL variant also requests the two ACL-gated permissions; install swaps
    # it in when it can prepare an ACL-capable profile, so the shell may start
    # `opencode serve` and reach host user files.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"opencode-desktop-unsigned.hap", "module.json")
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

    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is read-only in the CI container.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    # install-desktop.sh sources the shared install flow.
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/opencode-desktop.sh", libexec/"opencode-desktop.sh"
    chmod 0755, libexec/"opencode-desktop.sh"
    (bin/"opencode-app").write_env_script libexec/"opencode-desktop.sh",
      OPENCODE_DESKTOP_UNSIGNED_HAP:   libexec/"opencode-desktop-unsigned.hap",
      OPENCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      OPENCODE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      OPENCODE_DESKTOP_OPENCODE_BIN:   formula_opt_bin("opencode")/"opencode",
      OPENCODE_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                            "#{formula_opt_bin("node")}:#{formula_opt_bin("opencode")}:$PATH"
    bin.install_symlink bin/"opencode-app" => "opencode-desktop"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "opencode-app", "com.social4hyq.opencodedesktop"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install`/`brew upgrade` installs the HAP automatically once the
      device and the Huawei Developer login are ready; otherwise it is queued:
      `hap-app status` shows why, `hap-app install-pending` finishes it.
      Manual: `opencode-app install`. Details: docs/hap-app-formulae.md.

      The shell starts its own `opencode serve` on launch and shares the TUI
      sessions; the weak-sandbox ACLs (CUSTOM_SANDBOX, READ_WRITE_USER_FILE) come
      from the local debug profile. READ_PASTEBOARD enables paste and the kernel ACLs
      keep WebAssembly/markdown rendering. `--no-acl` installs the strong-sandbox HAP
      and waits for `opencode-app serve`.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: opencode-app", shell_output("#{bin}/opencode-desktop --help")
    assert_match "Usage: opencode-app", shell_output("#{bin}/opencode-app --help")

    # The app stages its config and permission variant; device and
    # signing-project work belongs to hap-installer.
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
    ENV["OPENCODE_DESKTOP_HDC"] = (fake_bin/"hdc").to_s

    saved_xdg = %w[XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME].to_h { |key| [key, ENV.fetch(key, nil)] }
    ENV["XDG_CONFIG_HOME"] = "/opencode-xdg-test/config"
    ENV["XDG_DATA_HOME"] = "/opencode-xdg-test/data"
    ENV.delete("XDG_STATE_HOME")
    assert_match "installed", shell_output("#{bin}/opencode-app install")
    config = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
    assert_operator config.fetch("port"), :>, 0
    refute_empty config.fetch("password")
    refute_empty config.fetch("opencode")
    assert_equal Dir.home, config.dig("host", "home")
    # XDG values reach the shell unchanged, so the spawned server reads the
    # terminal's config (an unset one is "").
    assert_equal "/opencode-xdg-test/config", config.dig("host", "xdgConfig")
    assert_equal "/opencode-xdg-test/data", config.dig("host", "xdgData")
    assert_equal "", config.dig("host", "xdgState")
    # Only this install runs with the test's XDG paths; the service below must
    # see the test environment.
    saved_xdg.each { |key, value| ENV[key] = value }
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_requested = acl_module.fetch("module").fetch("requestPermissions")
    acl_permissions = acl_requested.map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.opencodedesktop", installer[installer.index("--bundle-id") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal (fake_bin/"hdc").to_s, installer[installer.index("--hdc") + 1]
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    assert_match "installed", shell_output("#{bin}/opencode-app install --no-acl")
    strong = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 strong.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }.sort
    # --keep leaves the signed HAP in the temporary directory.
    kept_output = shell_output("#{bin}/opencode-app install --keep 2>&1")
    assert_match "installed (com.social4hyq.opencodedesktop, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists Pathname(ENV.fetch("TMPDIR", "/tmp"))/"opencode-app-signed.hap"

    assert_match "serving at", shell_output("#{bin}/opencode-app serve")
    assert_match "healthy", shell_output("#{bin}/opencode-app status")
    assert_match "stopped", shell_output("#{bin}/opencode-app stop")

    # `start --serve-only` keeps a CLI backend; `start` just opens the app.
    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete if fake_hdc.exist?
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match "serving at", shell_output("#{bin}/opencode-app start --serve-only")
    assert_match "opened", shell_output("#{bin}/opencode-app start")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.opencodedesktop -m electron],
                 serve_only_args.read.lines(chomp: true)
    assert_match "stopped", shell_output("#{bin}/opencode-app stop")

    hap = libexec/"opencode-desktop-unsigned.hap"
    assert_path_exists hap
    assert_path_exists pkgshare/"module-acl.json"
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/tray.cjs", listing
    assert_match "resources/resfile/resources/app/tray-icon.png", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "opencode-app status", waiting_source
    refute_match "{{", waiting_source
    tray_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/tray.cjs")
    assert_match "new Tray(", tray_source
    assert_match "app.exit(0)", tray_source
    window_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/main.cjs")
    assert_match "tray.create(", window_source
    assert_match "OPENCODE_DESKTOP_NO_TRAY", window_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package.fetch("version")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    permissions = profile.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
