class MagpieApp < Formula
  desc "Desktop shell for the Magpie model gateway"
  homepage "https://github.com/yetone/magpie"
  url "https://github.com/yetone/magpie/archive/refs/tags/v0.1.4777.tar.gz"
  sha256 "c47ccfbf93ba8953ab1b988cf513fe1dfa291eeb56c4bad6b839cc9ae7093361"
  license :cannot_represent

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/magpie-app-v0.1.4777-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afacf90e42da2241c3ff4e7a873e77b904df851205dabcf301db164496fd4704"
  end

  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "social4hyq/core/magpie"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/magpie-app/app/config.json
    Resources/magpie-app/app/connect.html
    Resources/magpie-app/app/main.cjs
    Resources/magpie-app/app/package.json
    Resources/magpie-app/app/shared-web.cjs
    Resources/magpie-app/scripts/install-desktop.sh
    Resources/magpie-app/scripts/magpie-app.sh
    Resources/magpie-app/tests/close-handler.test.cjs
    Resources/magpie-app/tests/fake-magpie.cjs
    Resources/magpie-app/tests/shared-web.test.cjs
    Resources/magpie-app/tests/shell-harness.cjs
    Resources/magpie-app/tests/shell-start.test.cjs
    Resources/magpie-app/tests/web-flow.test.cjs
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/magpie-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs package.json config.json connect.html shared-web.cjs].each do |name|
      cp res/"app"/name, app/name
    end

    icon = buildpath/"internal/gui/icon-256.png"
    cp icon, app/"tray-icon.png"
    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.magpiedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp icon, shell/"AppScope/resources/base/media"/name
    end
    # Locale overrides would otherwise keep the Electron launcher label.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "Magpie"
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
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.MICROPHONE", "reason": "$string:microphone", "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" } }
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

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "magpie-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['magpie-app']"
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
                    "magpie-desktop-unsigned.hap"

    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"magpie-desktop-unsigned.hap", "module.json")
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

    cp res/"scripts/magpie-app.sh", libexec/"magpie-app.sh"
    chmod 0755, libexec/"magpie-app.sh"
    # Pathname#install would move files out of the read-only CI tap.
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    (bin/"magpie-app").write_env_script libexec/"magpie-app.sh",
      MAGPIE_APP_UNSIGNED_HAP:   libexec/"magpie-desktop-unsigned.hap",
      MAGPIE_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      MAGPIE_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      MAGPIE_APP_BIN:            formula_opt_bin("social4hyq/core/magpie")/"magpie",
      MAGPIE_APP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                      "#{formula_opt_bin("node")}:$PATH"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "magpie-app", "com.social4hyq.magpiedesktop"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    hap = libexec/"magpie-desktop-unsigned.hap"
    entry = "resources/resfile/resources/app"
    system "unzip", "-tq", hap
    listing = shell_output("unzip -Z1 #{hap}")
    assert_match "libs/arm64-v8a/libelectron.so", listing
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    tests = tap_root/"Resources/magpie-app/tests"
    system "node", "--test", tests/"close-handler.test.cjs", tests/"shared-web.test.cjs",
           tests/"web-flow.test.cjs", tests/"shell-start.test.cjs"
    assert_match "#{entry}/connect.html", listing
    assert_match "#{entry}/shared-web.cjs", listing
    assert_match "Usage: magpie-app", shell_output("#{bin}/magpie-app --help")

    # The CLI matrix: start/stop/status address the device; uninstall goes
    # through app-installer and keeps the app's data unless --purge is given.
    fake_bin = testpath/"cli-bin"
    fake_bin.mkpath
    hdc_log = testpath/"cli-hdc-log"
    (fake_bin/"hdc").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$*" >> #{hdc_log}
      if [ "$1" = "shell" ] && [ "$2" = "ps -ef" ]; then
        if [ -z "${FAKE_STOPPED:-}" ]; then
          printf '%s\\n' "u 1 1 1 1 ? 00:00:00 com.social4hyq.magpiedesktop"
        fi
        printf '%s\\n' "u 1 1 1 1 ? 00:00:00 sh -c echo com.social4hyq.magpiedesktop"
      fi
    SH
    chmod 0755, fake_bin/"hdc"
    installer_args = testpath/"cli-installer-args"
    (fake_bin/"app-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
    SH
    chmod 0755, fake_bin/"app-installer"
    cli_env = {
      "MAGPIE_APP_HDC"       => (fake_bin/"hdc").to_s,
      "MAGPIE_APP_INSTALLER" => (fake_bin/"app-installer").to_s,
      "PATH"                 => "#{fake_bin}:#{ENV.fetch("PATH")}",
    }
    with_env(cli_env) do
      shell_output("#{bin}/magpie-app start --device tablet-1")
      assert_match "-t tablet-1 shell aa start", (testpath/"cli-hdc-log").read
      shell_output("#{bin}/magpie-app stop")
      assert_match "shell aa force-stop com.social4hyq.magpiedesktop", (testpath/"cli-hdc-log").read
      assert_match "running", shell_output("#{bin}/magpie-app status")
      with_env("FAKE_STOPPED" => "1") do
        assert_match "not running", shell_output("#{bin}/magpie-app status 2>&1", 1)
      end
      shell_output("#{bin}/magpie-app uninstall --purge --device tablet-1")
      assert_equal %w[uninstall --bundle-id com.social4hyq.magpiedesktop --device tablet-1 --purge],
                   installer_args.read.lines(chomp: true)
      shell_output("#{bin}/magpie-app uninstall")
      assert_equal %w[uninstall --bundle-id com.social4hyq.magpiedesktop], installer_args.read.lines(chomp: true)
    end
    with_env({ "HDC_TARGET" => "env-device" }.merge(cli_env)) do
      shell_output("#{bin}/magpie-app uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.magpiedesktop --device env-device],
                 installer_args.read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/magpie-app --help")

    fake = testpath/"app-installer"
    fake.write <<~SH
      #!/bin/sh
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{testpath}/staged.hap; shift 2 ;;
          --signed-hap) echo signed > "$2"; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake
    ENV.prepend_path "PATH", testpath
    ENV["HOME"] = testpath
    staged = testpath/"staged.hap"

    system bin/"magpie-app", "install"
    config = JSON.parse(shell_output("unzip -p #{staged} #{entry}/config.json"))
    assert_equal formula_opt_bin("social4hyq/core/magpie")/"magpie", Pathname(config.fetch("backend"))
    assert_equal testpath.to_s, config.dig("host", "HOME")
    refute config.key?("key")
    acl = JSON.parse(shell_output("unzip -p #{staged} module.json"))
    assert_equal "com.social4hyq.magpiedesktop", acl.fetch("app").fetch("bundleName")
    permissions = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.MICROPHONE ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 permissions.sort

    system bin/"magpie-app", "install", "--no-acl"
    assert_equal config, JSON.parse(shell_output("unzip -p #{staged} #{entry}/config.json"))
    plain = JSON.parse(shell_output("unzip -p #{staged} module.json"))
    permissions = plain.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.MICROPHONE], permissions.sort

    keep_tmp = testpath/"keep"
    keep_tmp.mkpath
    kept_output = with_env(TMPDIR: keep_tmp.to_s) do
      shell_output("#{bin}/magpie-app install --keep 2>&1")
    end
    assert_match "installed (com.social4hyq.magpiedesktop, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists keep_tmp/"magpie-app-signed.hap"
  end
end
