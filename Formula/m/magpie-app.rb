class MagpieApp < Formula
  desc "Desktop shell for the Magpie model gateway"
  homepage "https://github.com/yetone/magpie"
  url "https://github.com/yetone/magpie/archive/refs/tags/v0.1.4402.tar.gz"
  sha256 "a23a2867fe4aa3ae33ee83d5a554ba8283b9052d01c20c02c6bd2941bed47dcd"
  license :cannot_represent
  revision 5

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/magpie-app-v0.1.4402-r9"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e76b149675768019b5f51d611fade9b6bcf326114062b080d4871f94870fd290"
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

  # List every path literally: the unused-resource audit keeps a Resources/
  # directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/magpie-app/app/config.json
    Resources/magpie-app/app/connect.html
    Resources/magpie-app/app/main.cjs
    Resources/magpie-app/app/package.json
    Resources/magpie-app/scripts/install-desktop.sh
    Resources/magpie-app/scripts/magpie-app.sh
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/magpie-app"
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
    %w[main.cjs package.json config.json connect.html].each do |name|
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
    # Patch app name/labels in every locale: the base file alone leaves the
    # zh_CN/en_US overrides showing "Electron".
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

    # windowStageClose hides the ability and cancels the close, so the window
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
      odie "magpie-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['magpie-app']"
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
    # Sources the shared install flow; cp, not install: the tap checkout is
    # read-only in the CI container.
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

  def caveats
    <<~EOS
      `brew install`/`brew upgrade` installs the HAP automatically once the
      device and the Huawei Developer login are ready; otherwise it is queued:
      `hap-app status` shows why, `hap-app install-pending` finishes it.
      Manual: `magpie-app install`. Details: docs/hap-app-formulae.md.

      Starts the installed Magpie CLI and shares its settings; the web UI listens on
      loopback with a per-launch key. Needs a debug profile for READ_PASTEBOARD
      (paste). Without ACLs: `magpie-app install --no-acl`, then run
      `magpie web --addr 127.0.0.1:3430 --no-open` yourself.
    EOS
  end

  test do
    hap = libexec/"magpie-desktop-unsigned.hap"
    entry = "resources/resfile/resources/app"
    system "unzip", "-tq", hap
    listing = shell_output("unzip -Z1 #{hap}")
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "#{entry}/main.cjs", listing
    assert_match "Menu.setApplicationMenu(null)", shell_output("unzip -p #{hap} #{entry}/main.cjs")
    assert_match "#{entry}/connect.html", listing
    assert_match "#{entry}/tray-icon.png", listing
    assert_match "Usage: magpie-app", shell_output("#{bin}/magpie-app --help")

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
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 permissions.sort

    system bin/"magpie-app", "install", "--no-acl"
    # The strong-sandbox HAP has the same settings as the ACL one; only the
    # permissions differ.
    assert_equal config, JSON.parse(shell_output("unzip -p #{staged} #{entry}/config.json"))
    plain = JSON.parse(shell_output("unzip -p #{staged} module.json"))
    permissions = plain.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort

    # --keep leaves the signed HAP in the temporary directory.
    kept_output = shell_output("#{bin}/magpie-app install --keep 2>&1")
    assert_match "installed (com.social4hyq.magpiedesktop, ACL)", kept_output
    assert_match "signed HAP kept", kept_output
    assert_path_exists Pathname(ENV.fetch("TMPDIR", "/tmp"))/"magpie-app-signed.hap"
  end
end
