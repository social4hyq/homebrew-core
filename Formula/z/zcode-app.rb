class ZcodeApp < Formula
  desc "Desktop shell for the ZCode agent (Electron window on a local zcode --web)"
  homepage "https://zcode.z.ai"
  # Same upstream pin as `zcode`: the shell only provides the window, the web
  # workbench comes from the installed CLI, so both formulae are versioned
  # against the same upstream snapshot.
  url "https://github.com/zai-org/ZCode.git",
      revision: "fec975905a2abd4c07e35c40d51fa097a2258ec9"
  version "3.18.2"
  # Tap-authored shell scripts (MIT) packaging the CPF-Electron runtime
  # (Chromium/Electron, mixed MIT/BSD/LGPL).
  license :cannot_represent
  revision 12

  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-app-v3.18.2-r4"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62965bd6f91a803b9c6cbb76c25f8ff13fcc207e3988d6b1d9ee9e076cf457cf"
  end

  depends_on "app-installer"
  depends_on "bun"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zcode"
  depends_on "zip"

  # Shell sources live in the tap so they are reviewable in the PR and no
  # opaque release payload is involved. Every path is listed literally: the
  # weekly remove-unused-patches job keeps a Resources/ directory only while a
  # formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/electron-shell/tray.cjs
    Resources/zcode-app/app/config.json
    Resources/zcode-app/app/main.cjs
    Resources/zcode-app/app/package.json
    Resources/zcode-app/app/waiting.html
    Resources/zcode-app/assets/icon.png
    Resources/zcode-app/assets/tray-icon.png
    Resources/zcode-app/scripts/install-desktop.sh
    Resources/zcode-app/scripts/zcode-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/zcode-app"
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
    %w[main.cjs package.json config.json waiting.html].each do |name|
      cp res/"app"/name, app/name
    end
    cp tap_root/"Resources/_shared/electron-shell/tray.cjs", app/"tray.cjs"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.zcodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # App name and ability labels live in per-locale string resources: patching
    # only the base file leaves the zh_CN/en_US overrides intact and the
    # launcher keeps showing the template's "Electron" label.
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

    # Remove template signing settings and select the SDK supported by the
    # shared HAP build toolchain. This profile is strict JSON.
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

    # The shell only talks to the host service over loopback. Restricted
    # permissions (JIT, pasteboard) are added to the install-time ACL variant
    # instead of every install; see module-acl.json below.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    # The caption close button never reaches Electron's BrowserWindow close
    # event: electron-ohos tears down the window UIAbility first and the shell
    # exits with it. Register a windowStageClose handler that hides the ability
    # and cancels the close, so closing the window only sends it to the tray.
    # The tray's quit item calls app.exit() because a normal quit would be
    # cancelled here.
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

    # HAP shell build. CI runs in the private electron-ohos-ci image (the
    # generic Electron-on-OHOS build image, selected via the
    # OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the HarmonyOS
    # command-line toolchain at /opt/electron-ohos-clt — repacked from a
    # licensed system CLT install, not publicly redistributable. The shell
    # compiles no C++, so the NDK-less SDK subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "zcode-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['zcode-app']"
    end

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes and the libhilog stderr
    # adapter baked into the image.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it for the hvigor process tree
    # (only ever lowering — never raise an environment's existing limit).
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
                    "zcode-desktop-unsigned.hap"

    # The default install swaps in this module.json: the two kernel ACLs keep
    # the renderer out of --jitless (WebAssembly, so document previews and the
    # diff worker work) and READ_PASTEBOARD makes paste work. Everything else
    # stays out of the HAP so a local debug profile can grant it.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"zcode-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    # Register zcode://<host>/callback so the browser's OAuth handoff opens the
    # shell instead of OHOS's "no application can open this" dialog. The web
    # client finishes the login through the server poll; the handoff only has
    # to reach the app.
    entry = module_json.fetch("module").fetch("abilities").find { |ability| ability["name"] == "EntryAbility" }
    skills = entry["skills"] ||= []
    unless skills.any? { |skill| Array(skill["uris"]).any? { |uri| uri["scheme"] == "zcode" } }
      skills << {
        "actions" => ["ohos.want.action.viewData"],
        "uris"    => [{ "scheme" => "zcode" }],
      }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is a read-only host mount inside the CI container.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp res/"scripts/zcode-desktop.sh", libexec/"zcode-desktop.sh"
    chmod 0755, libexec/"zcode-desktop.sh"
    (bin/"zcode-app").write_env_script libexec/"zcode-desktop.sh",
      ZCODE_DESKTOP_UNSIGNED_HAP:   libexec/"zcode-desktop-unsigned.hap",
      ZCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      ZCODE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      ZCODE_DESKTOP_ZCODE:          formula_opt_bin("zcode")/"zcode",
      ZCODE_DESKTOP_ZCODE_ROOT:     formula_opt_prefix("zcode")/"libexec/zcode",
      ZCODE_DESKTOP_BUN:            formula_opt_bin("bun")/"bun",
      ZCODE_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                         "#{formula_opt_bin("node")}:$PATH"
    bin.install_symlink bin/"zcode-app" => "zcode-desktop"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run:

        zcode-app install

      app-installer generates a local debug profile (the first run asks for a
      Huawei Developer login), signs the HAP and installs it.

      `zcode-app install` also starts the backing `zcode --web` instance,
      so the app icon opens the workbench directly. The shell never starts the
      service itself; after a reboot start it again:

        zcode-app serve      # start it (the shell waits for it otherwise)
        zcode-app status
        zcode-app stop

      `serve` also creates ~/.zcode/v2/credential-secret and exports
      ZCODE_CREDENTIAL_SECRET_FILE. ZCode 3.18.2 refuses to start without a
      credential secret and HarmonyOS has no Secret Service, so the file is
      required even when no Z.ai account is used.

      Project routing: 3.18.2's `zcode --web` advertises itself as a remote
      source server, so the browser workbench's "this computer" projects are
      routed to a remote host and creating one fails with project.host-offline.
      `serve` therefore runs the bundled server from a per-version copy with
      projectStorageHostId pinned to "local". If that copy cannot be prepared it
      falls back to `zcode --web` and logs the warning.

      Account login: the workbench served on loopback signs in through the
      server-side OAuth flow (patched zcode): the login dialog's "browser
      authorization" button opens the authorize URL in the system browser and
      the server polls for the token. `zcode-app login [zai|bigmodel]` runs
      the same flow from the terminal and restarts the managed server. The HAP
      registers the zcode:// scheme so a browser handoff launches the shell
      instead of OHOS's "no application can open this" dialog.

      The default install carries the two kernel ACLs (JIT/WebAssembly for the
      renderer) and READ_PASTEBOARD; `zcode-app install --no-acl` installs
      the strong-sandbox variant instead (no JIT, no paste). 坚盾守护模式
      disables JIT regardless of the ACLs. The workbench's embedded terminal is
      unavailable because node-pty cannot spawn child processes under bun on
      HarmonyOS.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: zcode-app", shell_output("#{bin}/zcode-desktop --help")
    ENV.delete("XDG_CONFIG_HOME")
    assert_match "Usage: zcode-app", shell_output("#{bin}/zcode-app --help")

    # A minimal stand-in for the shell HAP: the installer only rewrites
    # config.json (and swaps module.json for the ACL variant), so the 200 MB
    # artifact does not need to be copied around in the test.
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
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_bin/"app-installer"

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"

    ENV.prepend_path "PATH", fake_bin
    ENV["ZCODE_DESKTOP_HDC"] = (fake_bin/"hdc").to_s

    # Default install: config injection, ACL module and signing project.
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
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD
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

    # --no-acl keeps the HAP's own permission list.
    assert_match "installed",
                 shell_output("#{bin}/zcode-app install --hap #{fake_hap} --no-acl --no-serve")
    strong_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    strong_requests = strong_module.dig("module", "requestPermissions")
    strong_permissions = strong_requests.map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.INTERNET], strong_permissions

    assert_match "no managed server running", shell_output("#{bin}/zcode-app stop")
    assert_match "not healthy", shell_output("#{bin}/zcode-app status 2>&1", 1)

    # The real bottle HAP.
    hap = libexec/"zcode-desktop-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/tray.cjs", listing
    assert_match "resources/resfile/resources/app/tray-icon.png", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    tray_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/tray.cjs")
    assert_match "new Tray(", tray_source
    assert_match "app.exit(0)", tray_source
    window_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/main.cjs")
    assert_match "tray.create(", window_source
    assert_match "ZCODE_DESKTOP_NO_TRAY", window_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort
    system "unzip", "-tq", hap
  end
end
