class OrcaApp < Formula
  desc "Desktop shell for the Orca agent runtime (Electron window on its web client)"
  homepage "https://github.com/stablyai/orca"
  # Version follows the Orca release; shell sources live in Resources/orca-app
  # and the host runtime comes from the `orca` formula (same upstream tag).
  url "https://github.com/stablyai/orca/archive/refs/tags/v1.4.261.tar.gz"
  sha256 "5b8a21bb9cde62a1dd7ca3c0ffd2f684faf168ea401191068777a8a9e7466909"
  # Tap-authored shell scripts (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent
  revision 9

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/orca-app-v1.4.261-r14"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "150ba45be5b6b7baa8bfb1b9f7965114af36bf070ef30178e243b05a5943f5fc"
  end

  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "orca"
  depends_on "unzip"
  depends_on "zip"

  # List every path literally: the unused-resource audit keeps a Resources/
  # directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/electron-shell/tray.cjs
    Resources/_shared/hap-app/install-lib.sh
    Resources/orca-app/app/config.json
    Resources/orca-app/app/main.cjs
    Resources/orca-app/app/package.json
    Resources/orca-app/app/waiting.html
    Resources/orca-app/assets/icon.png
    Resources/orca-app/assets/tray-icon.png
    Resources/orca-app/scripts/install-desktop.sh
    Resources/orca-app/scripts/orca-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/orca-app"
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
                                          '"bundleName": "com.social4hyq.orca"'
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
        when "app_name", "EntryAbility_label" then entry["value"] = "Orca"
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

    # The shell only talks to the runtime over loopback; restricted
    # permissions go into the ACL variant (module-acl.json).
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
      odie "orca-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['orca-app']"
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
                    "orca-app-unsigned.hap"

    # ACL variant: CUSTOM_SANDBOX and READ_WRITE_USER_FILE let the shell spawn
    # `orca` and read the host profile; the kernel ACLs keep WebAssembly and
    # READ_PASTEBOARD makes paste work.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"orca-app-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    pkgshare.mkpath
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is read-only in the CI container.
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    # install-desktop.sh sources the shared install flow.
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/orca-desktop.sh", libexec/"orca-desktop.sh"
    chmod 0755, libexec/"orca-desktop.sh"
    tool_path = [formula_opt_bin("node"), formula_opt_bin("zip"), formula_opt_bin("unzip"), "$PATH"].join(":")
    (bin/"orca-app").write_env_script libexec/"orca-desktop.sh",
      ORCA_DESKTOP_ROOT:           formula_opt_prefix("orca")/"libexec",
      ORCA_DESKTOP_ORCA_BIN:       formula_opt_bin("orca")/"orca",
      ORCA_DESKTOP_UNSIGNED_HAP:   libexec/"orca-app-unsigned.hap",
      ORCA_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      ORCA_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      ORCA_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                        tool_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "orca-app", "com.social4hyq.orca"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install`/`brew upgrade` installs the HAP automatically once the
      device and the Huawei Developer login are ready; otherwise it is queued:
      `hap-app status` shows why, `hap-app install-pending` finishes it.
      Manual: `orca-app install`. Details: docs/hap-app-formulae.md.

      The shell starts its host `orca serve` runtime on launch and reads the pairing
      link itself, so the app icon opens a working workbench. Weak-sandbox ACLs
      (CUSTOM_SANDBOX, READ_WRITE_USER_FILE) let it spawn `orca`; the local debug
      profile grants them. `orca-app serve` runs a separate host-side runtime in
      ~/.orca for browser/CLI use:

        orca-app start      # open the app
        orca-app status     # host-side runtime
        orca-app stop

      `install --no-acl` installs the strong-sandbox variant (no JIT/paste; it waits
      for `orca-app serve` instead of spawning the runtime).
    EOS
  end

  test do
    # The launcher keeps state in ~/.config/orca-app; HOME is the test sandbox.
    ENV["HOME"] = testpath/"home"
    ENV["XDG_CONFIG_HOME"] = testpath/"home/.config"
    assert_match "Usage: orca-app", shell_output("#{bin}/orca-app --help")

    # Minimal stand-in HAP: the installer only rewrites config.json and swaps
    # module.json.
    fake_hap = testpath/"shell.hap"
    hap_tree = testpath/"hap-tree"
    (hap_tree/"resources/resfile/resources/app").mkpath
    fake_module = { "name" => "electron", "requestPermissions" => [{ "name" => "ohos.permission.INTERNET" }] }
    (hap_tree/"module.json").write JSON.generate(
      "app"    => { "bundleName" => "com.social4hyq.orca" },
      "module" => fake_module,
    )
    (hap_tree/"resources/resfile/resources/app/config.json").write '{"port":0,"orca":"","host":{}}'
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
      printf '%s\\n' "$*" >> #{hdc_log}
      case "$*" in
        *"list targets -v"*) printf '%s\\n' "127.0.0.1:34561  Connected" ;;
      esac
    SH
    chmod 0755, fake_bin/"hdc"

    (fake_bin/"app-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --signed-hap) printf 'signed-by-fake' > "$2"; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_bin/"app-installer"

    ENV.prepend_path "PATH", fake_bin

    # Default install: spawn settings, ACL module and signing project.
    host_config = testpath/"host-config.json"
    host_config.write JSON.generate(
      "port" => 6799,
      "orca" => "/opt/homebrew/bin/orca",
      "host" => {
        "home" => "/home/tester",
        "path" => "/opt/homebrew/bin:/usr/bin:/bin",
      },
    )
    assert_match "installed",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-serve")
    injected_config = JSON.parse(
      shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"),
    )
    assert_equal 6799, injected_config.fetch("port")
    assert_equal "/opt/homebrew/bin/orca", injected_config.fetch("orca")
    assert_equal "/home/tester", injected_config.dig("host", "home")
    refute injected_config.fetch("host").key?("dataRoot")
    refute injected_config.key?("url")

    module_json = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = module_json.dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    assert_equal "acl\n", (testpath/"home/.config/orca-app/installed.mode").read
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.orca", installer[installer.index("--bundle-id") + 1]
    assert_equal "Orca", installer[installer.index("--app-name") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal "EntryAbility", installer[installer.index("--ability") + 1]
    # --no-acl keeps the HAP's own permission list.
    assert_match "installed",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-acl --no-serve")
    strong_permissions = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
                             .dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.INTERNET], strong_permissions

    # --keep is passed through; it does not change the installed variant.
    keep_tmp = testpath/"keep-tmp"
    keep_tmp.mkpath
    ENV["TMPDIR"] = keep_tmp.to_s
    keep_output = shell_output(
      "#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --keep --no-serve 2>&1",
    )
    assert_match "signed HAP kept at #{keep_tmp}/orca-app-signed.hap", keep_output
    assert_match "installed", keep_output
    assert_equal "signed-by-fake", (keep_tmp/"orca-app-signed.hap").read
    assert_equal "acl\n", (testpath/"home/.config/orca-app/installed.mode").read
    refute_match "signed HAP kept",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-serve 2>&1")

    # The automatic path sets HAP_INSTALLER_NO_START; no --no-serve needed.
    (testpath/"hdc-log").write("")
    with_env("HAP_INSTALLER_NO_START" => "1") do
      shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config}")
    end
    refute_match(/aa start/, (testpath/"hdc-log").read)

    # Pin the port to one this machine cannot have an Orca server on.
    (testpath/"home/.config/orca-app").mkpath
    (testpath/"home/.config/orca-app/config.json").write JSON.generate("port" => free_port)

    assert_match "no managed server running", shell_output("#{bin}/orca-app stop")
    assert_match "not healthy", shell_output("#{bin}/orca-app status 2>&1", 1)

    # A healthy server without a pairing file (as the shell's own runtime) is
    # reported as healthy with exit status 0.
    up_port = free_port
    (testpath/"home/.config/orca-app/config.json").delete
    (testpath/"home/.config/orca-app/config.json").write JSON.generate("port" => up_port)
    web = spawn(formula_opt_bin("node")/"node", "-e",
                "require('http').createServer((q, r) => { r.statusCode = q.url === '/web-index.html' ? 200 : 404; " \
                "r.end('ok'); }).listen(#{up_port}, '127.0.0.1')",
                [:out, :err] => File::NULL)
    begin
      60.times do
        TCPSocket.new("127.0.0.1", up_port).close
        break
      rescue Errno::ECONNREFUSED
        sleep 0.25
      end
      assert_match "healthy at http://127.0.0.1:#{up_port}", shell_output("#{bin}/orca-app status 2>&1")
    ensure
      Process.kill("TERM", web)
      Process.wait(web)
    end

    # State from an older launcher is moved to ~/.config/orca-app once.
    saved_home = Dir.home
    saved_xdg = ENV.fetch("XDG_CONFIG_HOME", nil)
    ENV["HOME"] = (testpath/"home2").to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"xdg2").to_s
    old_port = free_port
    (testpath/"xdg2/orca-app").mkpath
    (testpath/"xdg2/orca-app/config.json").write JSON.generate("port" => old_port)
    (testpath/"xdg2/orca-app/installed.mode").write "no-acl\n"
    moved = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "moved the state from #{testpath}/xdg2/orca-app to #{testpath}/home2/.config/orca-app", moved
    assert_match "not healthy at http://127.0.0.1:#{old_port}", moved
    assert_equal old_port, JSON.parse((testpath/"home2/.config/orca-app/config.json").read).fetch("port")
    assert_equal "no-acl\n", (testpath/"home2/.config/orca-app/installed.mode").read
    refute_path_exists testpath/"xdg2/orca-app/config.json"
    assert_path_exists testpath/"xdg2/orca-app/config.json.migrated"
    # A terminal without XDG_CONFIG_HOME now finds it, and nothing is moved again.
    ENV.delete("XDG_CONFIG_HOME")
    found = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "not healthy at http://127.0.0.1:#{old_port}", found
    refute_match "moved the state", found
    # An old config next to an existing one is ignored: renamed, one notice.
    ENV["XDG_CONFIG_HOME"] = (testpath/"xdg2").to_s
    (testpath/"xdg2/orca-app/config.json").write JSON.generate("port" => free_port)
    ignored = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "already has a config", ignored
    assert_match "not healthy at http://127.0.0.1:#{old_port}", ignored
    assert_path_exists testpath/"xdg2/orca-app/config.json.superseded"
    refute_path_exists testpath/"xdg2/orca-app/config.json"
    refute_match "already has a config", shell_output("#{bin}/orca-app status 2>&1", 1)
    ENV["HOME"] = saved_home
    ENV["XDG_CONFIG_HOME"] = saved_xdg

    # The real bottle HAP.
    hap = libexec/"orca-app-unsigned.hap"
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
    window_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/main.cjs")
    assert_match "tray.create(", window_source
    assert_match "ORCA_DESKTOP_NO_TRAY", window_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    refute placeholder.key?("url")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort
    shell_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/main.cjs")
    assert_match "spawn(", shell_source
    assert_match "orca_server_ready", shell_source
    system "unzip", "-tq", hap
  end
end
