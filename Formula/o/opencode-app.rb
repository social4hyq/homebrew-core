class OpencodeApp < Formula
  desc "Desktop shell for the OpenCode agent (Electron window on opencode service)"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v2.3.2.tar.gz"
  sha256 "de809cbf853ad98374961c525bd124e3e86bd285264b69fae53943a6e2dcdd5d"
  # Tap-authored shell sources (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent
  revision 2

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    throttle days: 1
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-app-v2.3.2-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc46f22f3e036a17ebeae75a48151f6b58bf57be7eeed53b83d4d9093131c396"
  end

  depends_on "app-installer"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "opencode"
  depends_on "unzip"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
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
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs config.json].each do |name|
      cp res/"app"/name, app/name
    end
    package = JSON.parse((res/"app/package.json").read)
    (app/"package.json").write JSON.generate(package.merge("version" => version.to_s))
    cp tap_root/"Resources/_shared/electron-shell/tray.cjs", app/"tray.cjs"
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
    # Locale overrides would otherwise keep the Electron launcher label.
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

    # The CI SDK lacks llvm-strip and local signing material.
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

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "opencode-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['opencode-app']"
    end

    # ohos_packing_tool needs SDK libraries outside brew's sanitized search path.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # An oversized RLIMIT_NOFILE breaks the musl FD table in hvigor.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

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

    # Pathname#install would move files out of the read-only CI tap.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
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
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `opencode-app install`. See docs/hap-app-formulae.md.

      The shell connects to the background service that `opencode` runs for the
      terminal (`opencode service`), so the TUI and the app show the same sessions.
      It starts that service on launch when it is not running, but a service the
      app starts ends when the app exits (quit or `aa force-stop`). To keep tasks
      running after the app is closed, start the service from a terminal first:
      `opencode-app serve` (or `opencode service start`; `opencode-app start
      --serve-only` in a shell startup file). A service started there survives
      the app, and `opencode-app stop` stops it. The weak-sandbox ACLs (CUSTOM_SANDBOX,
      READ_WRITE_USER_FILE) come from the local debug profile. READ_PASTEBOARD
      enables paste and the kernel ACLs keep WebAssembly/markdown rendering.
      `--no-acl` installs the strong-sandbox HAP and waits for `opencode-app serve`.
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
    refute_empty config.fetch("opencode")
    # The service address and password are read from its state file at run
    # time, never baked into the HAP.
    refute_includes config.keys, "port"
    refute_includes config.keys, "password"
    assert_equal Dir.home, config.dig("host", "home")
    # XDG values reach the shell unchanged, so the service it starts and the
    # state file it reads match the terminal's (an unset one is "").
    assert_equal "/opencode-xdg-test/config", config.dig("host", "xdgConfig")
    assert_equal "/opencode-xdg-test/data", config.dig("host", "xdgData")
    assert_equal "", config.dig("host", "xdgState")
    # Only this install runs with the test's XDG paths; the service commands
    # below must see the test environment.
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
    keep_tmp = testpath/"keep"
    keep_tmp.mkpath
    kept_output = with_env(TMPDIR: keep_tmp.to_s) do
      shell_output("#{bin}/opencode-app install --keep 2>&1")
    end
    assert_match "installed (com.social4hyq.opencodedesktop, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists keep_tmp/"opencode-app-signed.hap"

    # The service commands run against a fake `opencode` that only records its
    # arguments and a small server that answers like the real service, so the
    # test never touches (or collides with) a service running on this machine.
    calls = testpath/"opencode-calls"
    (fake_bin/"opencode").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$*" >> #{calls}
    SH
    chmod 0755, fake_bin/"opencode"
    ENV["OPENCODE_DESKTOP_OPENCODE"] = (fake_bin/"opencode").to_s
    state_dir = Pathname.new(Dir.home)/".local/state/opencode"
    state_dir.mkpath
    state_file = state_dir/"service.json"
    assert_match "not healthy", shell_output("#{bin}/opencode-app status 2>&1", 1)

    service_port = free_port
    (testpath/"fake-service.js").write <<~JS
      const http = require("node:http");
      const [port, password] = process.argv.slice(2);
      const expected = "Basic " + Buffer.from("opencode:" + password).toString("base64");
      http.createServer((req, res) => {
        res.statusCode = req.url === "/api/config" && req.headers.authorization === expected ? 200 : 401;
        res.end("{}");
      }).listen(Number(port), "127.0.0.1");
    JS
    state_file.write JSON.generate(id: "test", version: "2.2.7", url: "http://127.0.0.1:#{service_port}",
                                   pid: 1, password: "test-password")
    service_pid = spawn "node", (testpath/"fake-service.js").to_s, service_port.to_s, "test-password"
    begin
      20.times do
        break if quiet_system "curl", "-s", "-o", File::NULL, "http://127.0.0.1:#{service_port}/"

        sleep 0.25
      end
      assert_match "serving at http://127.0.0.1:#{service_port}", shell_output("#{bin}/opencode-app serve")
      assert_match "healthy at http://127.0.0.1:#{service_port}", shell_output("#{bin}/opencode-app status")
      state_file.atomic_write JSON.generate(url: "http://127.0.0.1:#{service_port}", password: "wrong")
      assert_match "not healthy", shell_output("#{bin}/opencode-app status 2>&1", 1)
      state_file.atomic_write JSON.generate(url: "http://127.0.0.1:#{service_port}", password: "test-password")
      assert_match "stopped", shell_output("#{bin}/opencode-app stop")
      assert_equal ["service start", "service stop"], calls.read.lines(chomp: true)
    ensure
      Process.kill "TERM", service_pid
      Process.wait service_pid
    end

    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete if fake_hdc.exist?
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match "opened", shell_output("#{bin}/opencode-app start")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.opencodedesktop -m electron],
                 serve_only_args.read.lines(chomp: true)

    hap = libexec/"opencode-desktop-unsigned.hap"
    assert_match "libs/arm64-v8a/libelectron.so", shell_output("unzip -Z1 #{hap}")
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "opencode-app status", waiting_source
    refute_match "{{", waiting_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_empty placeholder
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package.fetch("version")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    permissions = profile.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
