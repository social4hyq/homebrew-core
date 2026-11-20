class MulticaApp < Formula
  desc "Desktop shell for the Multica AI agent workspace (Electron HAP for OpenHarmony)"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.11.1.tar.gz"
  sha256 "8a8f2149447dfd0c178fca332f88b539560fa57a5075d67c6e440958de8d49fc"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)
  revision 4

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-app-v0.11.1-r4"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82fbf0ca8fb78000b21dafe41d05c3598e0158ffe71a9b12ff33e52d0660036f"
  end

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "app-installer"
  depends_on "multica"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/multica-app/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/multica-app/assets/tray-icon.png
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath

    # Normalize CRLF to LF so patches match the template lines consistently.
    %w[
      libelectron/ohos_hap/build-profile.json5
      libelectron/ohos_hap/electron/src/main/module.json5
      libelectron/ohos_hap/electron/src/main/resources/base/element/string.json
      libelectron/ohos_hap/electron/src/main/resources/en_US/element/string.json
      libelectron/ohos_hap/electron/src/main/resources/zh_CN/element/string.json
      libelectron/ohos_hap/web_engine/src/main/module.json5
    ].each do |relative_path|
      path = buildpath/relative_path
      path.binwrite(path.binread.gsub("\r\n", "\n")) if path.exist?
    end

    super
  end

  def install
    tap_root = Pathname(__dir__).parent.parent
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build",
             *std_go_args(output: libexec/"multica-desktop-bridge", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica-desktop-bridge"
    end

    # The Multica License is Apache-2.0 plus conditions and requires the full
    # license (and NOTICE, if present) to travel with redistributed binaries.
    pkgshare.install "LICENSE" => "MULTICA-LICENSE"
    cp "NOTICE", pkgshare/"MULTICA-NOTICE" if File.exist?("NOTICE")
    pkgshare.install "scripts/install-desktop-ohos.sh" => "install-desktop.sh"
    pkgshare.install "scripts/multica-desktop-ohos.sh" => "desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"desktop.sh"
    libexec.install "scripts/multica-desktop-dispatch-ohos.sh" => "multica-desktop-dispatch.sh"
    chmod 0755, libexec/"multica-desktop-dispatch.sh"
    # The daemon inherits this env; it flocks its per-task temp dir, which /tmp
    # refuses on OHOS.
    (bin/"multica-app").write_env_script libexec/"multica-desktop-dispatch.sh",
      MULTICA_AGENT_TEMP_BASE: "${MULTICA_AGENT_TEMP_BASE:-/data/storage/el2/base/cache}",
      MULTICA_DESKTOP:         pkgshare/"desktop.sh",
      MULTICA_DESKTOP_BRIDGE:  libexec/"multica-desktop-bridge",
      MULTICA_DESKTOP_VERSION: version.to_s,
      MULTICA_HDC:             formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      MULTICA_INSTALL_DESKTOP: pkgshare/"install-desktop.sh",
      MULTICA_MODULE_ACL:      pkgshare/"module-acl.json",
      MULTICA_REAL_CLI:        formula_opt_prefix("multica")/"libexec/multica-cli",
      MULTICA_UNSIGNED_HAP:    libexec/"multica-desktop-unsigned.hap",
      MULTICA_ZIP:             formula_opt_bin("zip")/"zip",
      PATH:                    "#{formula_opt_bin("node")}:$PATH"

    shell = buildpath/"libelectron/ohos_hap"

    # Give this app its own bundle name: the vendor template's is shared, so
    # two Electron apps installed from it would displace each other.
    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.multica"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    inreplace shell/"electron/src/main/resources/base/profile/shortcuts_config.json",
              '"bundleName": "com.huawei.ohos_electron"',
              '"bundleName": "com.social4hyq.multica"'

    # hideAbility() must run synchronously before the teardown; hiding afterwards
    # makes the app exit. The tray quit calls app.exit() to bypass the close
    # handler and keep the bridge alive.
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

    ENV["CI"] = "true"
    system "npm", "exec", "--yes", "--", "pnpm@10.28.2", "install",
           "--ignore-scripts", "--frozen-lockfile", "--reporter=append-only"
    if OS.ohos?
      # Sign .node bindings so electron-vite can dlopen them on device.
      system "npm", "exec", "--yes", "--", "pnpm@10.28.2", "run", "postinstall"
    end
    cd "apps/desktop" do
      ENV["VITE_API_URL"] = "https://api.multica.ai"
      ENV["VITE_WS_URL"] = "wss://api.multica.ai/ws"
      ENV["VITE_APP_URL"] = "https://multica.ai"
      system "node", "--input-type=module", "-e",
             'import {build} from "electron-vite"; await build({server:{host:"127.0.0.1"}})'
    end

    %w[app_icon.png startIcon.png].each do |name|
      cp buildpath/"apps/desktop/build/icon.png", shell/"AppScope/resources/base/media"/name
    end

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app/"out" if (app/"out").exist?
    cp_r buildpath/"apps/desktop/out", app/"out"
    cp tap_root/"Resources/multica-app/assets/tray-icon.png", app/"out/main/tray-icon.png"
    rm_r app/"node_modules" if (app/"node_modules").exist?
    package = JSON.parse((buildpath/"apps/desktop/package.json").read)
    package = package.slice("name", "productName", "version", "description", "main", "private", "type")
    package["dependencies"] = %w[@electron-toolkit/utils electron-updater].to_h do |name|
      dependency = JSON.parse((buildpath/"apps/desktop/node_modules"/name/"package.json").read)
      [name, dependency.fetch("version")]
    end
    rm app/"package.json"
    (app/"package.json").write JSON.generate(package)
    cd app do
      system "npm", "install", *std_npm_args(prefix: false), "--omit=dev"
    end
    system "node", "-e", <<~'JS', app.to_s
      const fs = require("node:fs");
      const { createRequire, builtinModules } = require("node:module");
      const root = process.argv[1];
      const runtime = createRequire(root + "/package.json");
      for (const entry of ["main", "preload"]) {
        const code = fs.readFileSync(root + "/out/" + entry + "/index.js", "utf8");
        for (const match of code.matchAll(/require\(["']([^"']+)["']\)/g)) {
          const name = match[1];
          if (name === "electron" || name.startsWith("node:") || builtinModules.includes(name)) continue;
          runtime.resolve(name);
        }
      }
    JS

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "multica-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['multica-app']"
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
                    "multica-desktop-unsigned.hap"

    # The ACL variant also requests the two ACL-gated permissions
    # (`--acl-profile`).
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"multica-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)
    bin.install_symlink bin/"multica-app" => "multica-desktop"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "multica-app", "com.social4hyq.multica"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `multica-app install`. See docs/hap-app-formulae.md.

      The CLI and daemon come from the `multica` formula; keep both versions equal
      (`multica-app` warns when they differ). The desktop runs in its sandbox, so a
      loopback bridge runs on the host: `multica-app` starts it and opens the app,
      `multica-app stop` stops it. To start only the bridge from a login script,
      use the absolute path because it may run before Homebrew's bin is on PATH:

        "#{opt_bin}/multica-app" start --bridge-only

      The default HAP requests INTERNET and GET_NETWORK_INFO only; with an AGC
      profile carrying CUSTOM_SANDBOX/READ_WRITE_USER_FILE use
      `install --acl-profile <build-profile.json5>`. The bundle is
      `com.social4hyq.multica`; older `com.huawei.ohos_electron` copies are left in
      place.
    EOS
  end

  test do
    require "net/http"

    ENV["HOME"] = testpath/"home"
    assert_match "Usage: multica-app", shell_output("#{bin}/multica-desktop --help")
    assert_match "Usage: multica-app <command>", shell_output("#{bin}/multica-app --help")
    assert_match "Usage: multica-app install", shell_output("#{bin}/multica-app install --help")
    launcher_help = with_env(MULTICA_DESKTOP_BRIDGE: (libexec/"multica-desktop-bridge").to_s) do
      shell_output("#{pkgshare}/desktop.sh --help")
    end
    assert_match "Usage: multica-app [start|stop|status]", launcher_help
    assert_match "unknown command: bogus", shell_output("#{bin}/multica-app bogus 2>&1", 2)
    cli = formula_opt_prefix("multica")/"libexec/multica-cli"
    cli_version = Formula["multica"].version.to_s
    # The bridge outlives `brew upgrade`: point it at the stable opt path, not a
    # Cellar directory.
    wrapper = (bin/"multica-app").read
    assert_match cli.to_s, wrapper
    refute_match "Cellar/multica/", wrapper
    assert_match "MULTICA_DESKTOP_VERSION=\"#{version}\"", wrapper
    # The bridge's daemon flocks a temp dir that /tmp refuses on OHOS: carry a
    # usable base (an explicit user value wins).
    temp_base = "/data/storage/el2/base/cache"
    assert_match "MULTICA_AGENT_TEMP_BASE=\"${MULTICA_AGENT_TEMP_BASE:-#{temp_base}}\"", wrapper
    env_probe = testpath/"env-probe"
    env_probe.write wrapper.sub(/exec "[^"]*multica-desktop-dispatch\.sh"/, "exec env")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{temp_base}\n",
                 shell_output("env -u MULTICA_AGENT_TEMP_BASE sh #{env_probe}")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{testpath}/custom\n",
                 shell_output("MULTICA_AGENT_TEMP_BASE=#{testpath}/custom sh #{env_probe}")
    # Startup files may run before Homebrew's bin is on PATH: document the
    # absolute path.
    assert_match "\"#{opt_bin}/multica-app\" start --bridge-only", caveats
    assert_match "before Homebrew's bin is on PATH", caveats
    refute_match "`multica-app start --bridge-only`", caveats
    refute_match "github.com/social4hyq", caveats
    desktop_installer = pkgshare/"install-desktop.sh"
    zip = formula_opt_bin("zip")/"zip"
    unsigned_hap = testpath/"desktop.hap"
    app_dir = testpath/"hap/resources/resfile/resources/app"
    app_dir.mkpath
    (app_dir/"package.json").write "{}"
    cd testpath/"hap" do
      system zip, "-q", "-r", unsigned_hap, "resources"
    end
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    fake_cli = fake_bin/"multica-cli"
    fake_cli.write <<~SH
      #!/bin/sh
      echo "multica 9.9.9 (commit: x, built: y)"
    SH
    chmod 0755, fake_cli
    mismatch = with_env(MULTICA_REAL_CLI: fake_cli.to_s, MULTICA_DESKTOP_VERSION: version.to_s,
                        MULTICA_INSTALL_DESKTOP: desktop_installer.to_s) do
      shell_output("#{libexec}/multica-desktop-dispatch.sh install --help 2>&1")
    end
    assert_match "warning: the multica CLI is 9.9.9 but this desktop is #{version}", mismatch
    assert_match "Usage: multica-app install", mismatch
    matching = with_env(MULTICA_REAL_CLI: cli.to_s, MULTICA_DESKTOP_VERSION: cli_version,
                        MULTICA_INSTALL_DESKTOP: desktop_installer.to_s) do
      shell_output("#{libexec}/multica-desktop-dispatch.sh install --help 2>&1")
    end
    refute_match "warning", matching
    installer_args = testpath/"hap-installer-args"
    injected_hap = testpath/"injected.hap"
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        [ "$1" = --hap ] && cp "$2" #{injected_hap}
        shift
      done
    SH
    chmod 0755, fake_installer
    ENV["MULTICA_UNSIGNED_HAP"] = unsigned_hap.to_s
    ENV["MULTICA_DESKTOP"] = (pkgshare/"desktop.sh").to_s
    ENV["MULTICA_DESKTOP_BRIDGE"] = (libexec/"multica-desktop-bridge").to_s
    ENV["MULTICA_DESKTOP_STATE"] = (testpath/"state").to_s
    ENV["MULTICA_REAL_CLI"] = cli.to_s
    ENV["MULTICA_ZIP"] = zip.to_s
    ENV.prepend_path "PATH", fake_bin
    signer_args = testpath/"signer-args"
    signer_input = testpath/"signer-input.hap"
    fake_signer = fake_bin/"app-installer-sign"
    fake_signer.write <<~SH
      #!/bin/sh
      printf '%s\n' "$*" > #{signer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) hap_in="$2" ;;
          --output) hap_out="$2" ;;
        esac
        shift
      done
      cp "$hap_in" #{signer_input}
      cp "$hap_in" "$hap_out"
    SH
    chmod 0755, fake_signer
    begin
      shell_output(desktop_installer.to_s)
      args = installer_args.read.lines(chomp: true)
      assert_equal "--hap", args.first
      refute_equal unsigned_hap.to_s, args[1]
      assert_equal ["--bundle-id", "com.social4hyq.multica", "--app-name", "MulticaSigning",
                    "--module", "electron", "--ability", "EntryAbility"], args.drop(2)

      pairing = testpath/"home/.multica/desktop-bridge.json"
      assert_equal pairing.read,
                   shell_output("unzip -p #{injected_hap} resources/resfile/resources/app/desktop-bridge.json")
      assert_match "bridge: running", shell_output("#{pkgshare}/desktop.sh status")
      refute_path_exists signer_args
      refute_match(/module\.json$/, shell_output("unzip -l #{injected_hap}"))

      ENV["MULTICA_MODULE_ACL"] = (pkgshare/"module-acl.json").to_s
      (testpath/"build-profile.json5").write "{}"
      shell_output("#{desktop_installer} --acl-profile #{testpath}/build-profile.json5")
      acl_args = installer_args.read.lines(chomp: true)
      assert_equal "#{testpath}/build-profile.json5", acl_args[acl_args.index("--profile") + 1]
      refute_path_exists signer_args
      signed_module = JSON.parse(shell_output("unzip -p #{injected_hap} module.json"))
      signed_permissions = signed_module.fetch("module").fetch("requestPermissions").map do |permission|
        permission.fetch("name")
      end
      assert_includes signed_permissions, "ohos.permission.CUSTOM_SANDBOX"
      assert_includes signed_permissions, "ohos.permission.READ_WRITE_USER_FILE"
      assert_equal pairing.read,
                   shell_output("unzip -p #{injected_hap} resources/resfile/resources/app/desktop-bridge.json")

      paired = JSON.parse(pairing.read)
      base = URI("http://127.0.0.1:#{paired.fetch("port")}")
      health = JSON.parse(Net::HTTP.get(base + "/health"))
      assert_equal [true, true], [health.fetch("ok"), health.fetch("cli_ok")]
      body = JSON.generate("args" => ["version", "--output", "json"])
      denied = Net::HTTP.post(base + "/exec", body, "Content-Type" => "application/json")
      assert_equal "401", denied.code
      allowed = Net::HTTP.post(base + "/exec", body, "Content-Type"  => "application/json",
                                                     "Authorization" => "Bearer #{paired.fetch("secret")}")
      assert_equal "200", allowed.code
      assert_match cli_version, JSON.parse(allowed.body).fetch("stdout")

      # A bridge from a keg that later disappears is reported stale and replaced
      # by `multica-app start`.
      old_keg = testpath/"old-keg"
      old_keg.mkpath
      ln_s cli, old_keg/"multica-cli"
      system pkgshare/"desktop.sh", "stop"
      ENV["MULTICA_REAL_CLI"] = (old_keg/"multica-cli").to_s
      system pkgshare/"desktop.sh", "start", "--bridge-only"
      assert_match "bridge: running", shell_output("#{pkgshare}/desktop.sh status")
      rm_r old_keg
      assert_match "bridge: stale", shell_output("#{pkgshare}/desktop.sh status", 1)
      ENV["MULTICA_REAL_CLI"] = cli.to_s
      system pkgshare/"desktop.sh", "start", "--bridge-only"
      assert_match "bridge: running", shell_output("#{pkgshare}/desktop.sh status")
      replaced = Net::HTTP.post(base + "/exec", body, "Content-Type"  => "application/json",
                                                      "Authorization" => "Bearer #{paired.fetch("secret")}")
      assert_equal "200", replaced.code
      assert_match cli_version, JSON.parse(replaced.body).fetch("stdout")
    ensure
      system pkgshare/"desktop.sh", "stop"
    end
    refute_path_exists libexec/"node_modules"
    refute_path_exists libexec/"multica-cli"
    hap = libexec/"multica-desktop-unsigned.hap"
    listing = shell_output("unzip -l #{hap}")
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/out/main/index.js", listing
    refute_match "node_modules/typescript/", listing
    refute_match "node_modules/@multica/eslint-config/", listing
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_empty package.fetch("devDependencies", {})
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    # The vendor bundle name is shared; installing under it would displace
    # another app.
    assert_equal "com.social4hyq.multica", profile.fetch("app").fetch("bundleName")
    assert_equal "social4hyq", profile.fetch("app").fetch("vendor")
    assert_match 'BUNDLE_ID="com.social4hyq.multica"', desktop_installer.read
    assert_match 'BUNDLE_ID="com.social4hyq.multica"', (pkgshare/"desktop.sh").read
    # ArkTS records embed the bundle name: the compiled payload and the
    # manifest must match.
    bytecode = Utils.safe_popen_read("unzip", "-p", hap, "ets/modules.abc")
    assert_includes bytecode.force_encoding(Encoding::BINARY), "com.social4hyq.multica"
    # hvigor reformats the JSON (tabs instead of spaces), so match loosely.
    assert_match(/"bundleName":\s*"com\.social4hyq\.multica"/,
                 shell_output("unzip -p #{hap} resources/base/profile/shortcuts_config.json"))
    # The launcher label comes from string resources, not productName.
    resource_index = Utils.safe_popen_read("unzip", "-p", hap, "resources.index")
    resource_index = resource_index.force_encoding(Encoding::BINARY)
    assert_includes resource_index, "Multica"
    refute_includes resource_index, "multica"
    assert profile.fetch("module").fetch("extractNativeLibs")
    schemes = profile.fetch("module").fetch("abilities").flat_map do |ability|
      ability.fetch("skills", []).flat_map { |skill| skill.fetch("uris", []).map { |uri| uri["scheme"] } }
    end
    assert_includes schemes, "multica"
    permissions = profile.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl_module = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl_module.fetch("module").fetch("requestPermissions").map do |permission|
      permission.fetch("name")
    end
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_WRITE_USER_FILE], acl_permissions.sort
    assert_equal profile.fetch("module").except("requestPermissions"),
                 acl_module.fetch("module").except("requestPermissions")
    assert_equal %w[@electron-toolkit/utils electron-updater], package.fetch("dependencies").keys.sort
    system "unzip", "-tq", hap
  end
end
