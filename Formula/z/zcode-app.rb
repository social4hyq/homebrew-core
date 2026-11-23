class ZcodeApp < Formula
  desc "Desktop shell for the ZCode agent (Electron window on a local zcode --web)"
  homepage "https://zcode.z.ai"
  # Same upstream pin as `zcode`: the shell only provides the window, the
  # workbench comes from the installed CLI.
  url "https://github.com/zai-org/ZCode.git",
      revision: "fec975905a2abd4c07e35c40d51fa097a2258ec9"
  version "3.18.2"
  # Tap-authored shell scripts (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent
  revision 29

  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-app-v3.18.2-r35"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "153f7d0f9acc09934a4f8e6556e4a170c62c5005572e990a1816fd599d0975ad"
  end

  depends_on "app-installer"
  depends_on "bun"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zcode"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/_shared/waiting-page/render-waiting.cjs
    Resources/_shared/waiting-page/waiting.html.in
    Resources/zcode-app/app/config.json
    Resources/zcode-app/app/lifecycle.cjs
    Resources/zcode-app/app/main.cjs
    Resources/zcode-app/app/package.json
    Resources/zcode-app/app/server-auth.cjs
    Resources/zcode-app/app/tray.cjs
    Resources/zcode-app/app/waiting.json
    Resources/zcode-app/assets/icon.png
    Resources/zcode-app/assets/tray-icon.png
    Resources/zcode-app/scripts/install-desktop.sh
    Resources/zcode-app/scripts/zcode-desktop.sh
    Resources/zcode-app/tests/close-handler.test.cjs
    Resources/zcode-app/tests/lifecycle.test.cjs
    Resources/zcode-app/tests/server-auth.test.cjs
    Resources/zcode-app/tests/tray.test.cjs
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/zcode-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs lifecycle.cjs server-auth.cjs tray.cjs package.json config.json].each do |name|
      cp res/"app"/name, app/name
    end
    system "node", tap_root/"Resources/_shared/waiting-page/render-waiting.cjs",
           tap_root/"Resources/_shared/waiting-page/waiting.html.in",
           res/"app/waiting.json", app/"waiting.html"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.zcodedesktop"'
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
        when "app_name", "EntryAbility_label" then entry["value"] = "ZCode"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # Remove template signing settings and select the shared toolchain's SDK;
    # this profile is strict JSON.
    profile = JSON.parse((shell/"build-profile.json5").read)
    profile.fetch("app").fetch("products").each do |product|
      product.delete("signingConfig")
      product["compatibleSdkVersion"] = "6.0.0(20)"
    end
    profile.fetch("app").delete("signingConfigs")
    profile_file = shell/"build-profile.json5"
    rm profile_file
    profile_file.write JSON.pretty_generate(profile) + "\n"
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # The shell only talks to the host service over loopback; restricted
    # permissions go into the ACL variant (module-acl.json).
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

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "zcode-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['zcode-app']"
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
                    "zcode-desktop-unsigned.hap"

    # ACL variant: CUSTOM_SANDBOX and READ_WRITE_USER_FILE let the shell run the
    # host zcode-app on launch; the kernel ACLs keep WebAssembly (previews, diff
    # worker) and READ_PASTEBOARD makes paste work.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"zcode-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    # Register zcode://<host>/callback so the browser OAuth handoff opens the
    # shell; the web client finishes the login through the server poll.
    entry = module_json.fetch("module").fetch("abilities").find { |ability| ability["name"] == "EntryAbility" }
    skills = entry["skills"] ||= []
    unless skills.any? { |skill| Array(skill["uris"]).any? { |uri| uri["scheme"] == "zcode" } }
      skills << {
        "actions" => ["ohos.want.action.viewData"],
        "uris"    => [{ "scheme" => "zcode" }],
      }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # Pathname#install would move files out of the read-only CI tap.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/zcode-desktop.sh", libexec/"zcode-desktop.sh"
    chmod 0755, libexec/"zcode-desktop.sh"
    (bin/"zcode-app").write_env_script libexec/"zcode-desktop.sh",
      ZCODE_DESKTOP_UNSIGNED_HAP:   libexec/"zcode-desktop-unsigned.hap",
      ZCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      ZCODE_DESKTOP_LAUNCHER:       opt_bin/"zcode-app",
      ZCODE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      ZCODE_DESKTOP_ZCODE:          formula_opt_bin("zcode")/"zcode",
      ZCODE_DESKTOP_ZCODE_ROOT:     formula_opt_prefix("zcode")/"libexec/zcode",
      ZCODE_DESKTOP_BUN:            formula_opt_bin("bun")/"bun",
      ZCODE_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                         "#{formula_opt_bin("node")}:$PATH"
    bin.install_symlink bin/"zcode-app" => "zcode-desktop"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "zcode-app", "com.social4hyq.zcodedesktop"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      The backing service now requires a token for its API and websocket. It is
      created at ~/.zcode/v2/desktop-token and read by both zcode-app and the
      desktop app. A service started by an older version answers without it and
      is not reused: quit the app (or stop that process) and run
      `zcode-app serve` once after upgrading.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: zcode-app", shell_output("#{bin}/zcode-desktop --help")
    ENV.delete("XDG_CONFIG_HOME")
    assert_match "Usage: zcode-app", shell_output("#{bin}/zcode-app --help")

    # Minimal stand-in HAP: the installer only rewrites config.json and swaps
    # module.json.
    fake_hap = testpath/"shell.hap"
    hap_tree = testpath/"hap-tree"
    (hap_tree/"resources/resfile/resources/app").mkpath
    fake_module = { "name" => "electron", "requestPermissions" => [{ "name" => "ohos.permission.INTERNET" }] }
    (hap_tree/"module.json").write JSON.generate(
      "app"    => { "bundleName" => "com.social4hyq.zcodedesktop" },
      "module" => fake_module,
    )
    (hap_tree/"resources/resfile/resources/app/config.json").write '{"port":0}'
    cd hap_tree do
      system "zip", "-q", "-X", fake_hap.to_s, "module.json",
             "resources/resfile/resources/app/config.json"
    end

    fake_bin = testpath/"bin"
    fake_bin.mkpath
    installer_args = testpath/"hap-installer-args"
    injected_copy = testpath/"injected.hap"
    hdc_log = testpath/"hdc-log"

    (fake_bin/"hdc").write <<~SH
      #!/bin/sh
      printf '%s\n' "$*" >> #{hdc_log}
      case "$*" in
        *"list targets -v"*) printf '%s\n' "127.0.0.1:34561  Connected" ;;
      esac
    SH
    chmod 0755, fake_bin/"hdc"

    (fake_bin/"app-installer").write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --signed-hap) printf 'signed-by-fake' > "$2"; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_bin/"app-installer"

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"

    ENV.prepend_path "PATH", fake_bin
    ENV["ZCODE_DESKTOP_HDC"] = (fake_bin/"hdc").to_s
    ENV["ZCODE_DESKTOP_INSTALLER"] = (fake_bin/"app-installer").to_s

    # uninstall goes through app-installer and keeps the app's data unless
    # --purge is given; --device/HDC_TARGET pick the hdc target.
    shell_output("#{bin}/zcode-app uninstall --purge --device tablet-1")
    assert_equal %w[uninstall --bundle-id com.social4hyq.zcodedesktop --device tablet-1 --purge],
                 installer_args.read.lines(chomp: true)
    shell_output("#{bin}/zcode-app uninstall")
    assert_equal %w[uninstall --bundle-id com.social4hyq.zcodedesktop], installer_args.read.lines(chomp: true)
    with_env("HDC_TARGET" => "env-device") do
      shell_output("#{bin}/zcode-app uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.zcodedesktop --device env-device],
                 installer_args.read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/zcode-app --help")

    assert_match "installed", shell_output("#{bin}/zcode-app install --hap #{fake_hap} --no-serve")
    host_config = JSON.parse((testpath/"home/.config/zcode-desktop/config.json").read)
    assert_operator host_config.fetch("port"), :>, 0
    assert_equal Dir.home, host_config.fetch("workspace")
    assert_path_exists testpath/"home/.zcode/v2/credential-secret"
    injected_config = JSON.parse(
      shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"),
    )
    assert_equal host_config.fetch("port"), injected_config.fetch("port")
    assert_equal Dir.home, injected_config.fetch("workspace")
    assert_equal (opt_bin/"zcode-app").to_s, injected_config.fetch("launcher")
    assert_equal Dir.home, injected_config.dig("host", "home")
    assert_includes injected_config.dig("host", "path"), fake_bin.to_s
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.zcodedesktop", installer[installer.index("--bundle-id") + 1]
    assert_equal "ZCode", installer[installer.index("--app-name") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal "EntryAbility", installer[installer.index("--ability") + 1]
    assert_equal (fake_bin/"hdc").to_s, installer[installer.index("--hdc") + 1]

    assert_match "installed",
                 shell_output("#{bin}/zcode-app install --hap #{fake_hap} --no-acl --no-serve")
    strong_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    strong_requests = strong_module.dig("module", "requestPermissions")
    strong_permissions = strong_requests.map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.INTERNET], strong_permissions

    keep_tmp = testpath/"keep-tmp"
    keep_tmp.mkpath
    ENV["TMPDIR"] = keep_tmp.to_s
    keep_output = shell_output("#{bin}/zcode-app install --hap #{fake_hap} --keep --no-serve 2>&1")
    assert_match "signed HAP kept at #{keep_tmp}/zcode-desktop-signed.hap", keep_output
    assert_match "installed", keep_output
    assert_equal "signed-by-fake", (keep_tmp/"zcode-desktop-signed.hap").read
    refute_match "signed HAP kept",
                 shell_output("#{bin}/zcode-app install --hap #{fake_hap} --no-serve 2>&1")

    plain_output = shell_output("#{bin}/zcode-app install --hap #{fake_hap} 2>&1")
    assert_match "installed", plain_output
    refute_match "bundled server", plain_output
    refute_path_exists testpath/"home/.config/zcode-desktop/web.pid"

    assert_match "opened com.social4hyq.zcodedesktop", shell_output("#{bin}/zcode-app start --no-serve")
    assert_match "aa start -a EntryAbility -b com.social4hyq.zcodedesktop -m electron", hdc_log.read
    assert_match "unknown start option: --bogus", shell_output("#{bin}/zcode-app start --bogus 2>&1", 1)

    sleeper = spawn("sleep", "60")
    pid_file = testpath/"home/.config/zcode-desktop/web.pid"
    pid_file.write sleeper.to_s
    assert_match "zcode-desktop: stopped", shell_output("#{bin}/zcode-app stop")
    Process.wait(sleeper)
    refute_path_exists pid_file

    assert_match "no managed server running", shell_output("#{bin}/zcode-app stop")
    assert_match "not healthy", shell_output("#{bin}/zcode-app status 2>&1", 1)

    legacy = testpath/"xdg/zcode-desktop"
    legacy.mkpath
    old_port = free_port
    (legacy/"config.json").write JSON.generate("port" => old_port, "workspace" => "/legacy")
    moved = shell_output("XDG_CONFIG_HOME=#{testpath}/xdg #{bin}/zcode-app status 2>&1", 1)
    assert_match "moved the service state", moved
    assert_match "http://127.0.0.1:#{old_port}", moved
    assert_equal old_port, JSON.parse((testpath/"home/.config/zcode-desktop/config.json").read).fetch("port")
    assert_path_exists legacy/"config.json.migrated"
    refute_path_exists legacy/"config.json"
    refute_match "moved the service state", shell_output("#{bin}/zcode-app status 2>&1", 1)

    hap = libexec/"zcode-desktop-unsigned.hap"
    assert_match "libs/arm64-v8a/libelectron.so", shell_output("unzip -Z1 #{hap}")
    assert_match "resources/resfile/resources/app/lifecycle.cjs", shell_output("unzip -Z1 #{hap}")
    assert_match "resources/resfile/resources/app/server-auth.cjs", shell_output("unzip -Z1 #{hap}")
    assert_match "onQuitRequest", shell_output("unzip -p #{hap} resources/resfile/resources/app/tray.cjs")
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "node", "--check", tap_root/"Resources/zcode-app/app/main.cjs"
    system "node", "--test", tap_root/"Resources/zcode-app/tests/lifecycle.test.cjs"
    system "node", "--test", tap_root/"Resources/zcode-app/tests/server-auth.test.cjs"
    system "node", "--test", tap_root/"Resources/zcode-app/tests/tray.test.cjs"
    system "node", "--test", tap_root/"Resources/zcode-app/tests/close-handler.test.cjs"
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "zcode-app status", waiting_source
    refute_match "{{", waiting_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort
    system "unzip", "-tq", hap
  end
end
