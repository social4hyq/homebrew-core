class MulticaDesktop < Formula
  desc "Desktop shell for the Multica AI agent workspace (Electron HAP for OpenHarmony)"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "c52ffa09412bfc0f6cd6bed0900a66252b1c30f355f257f991a62a88e121eac8"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)
  revision 2

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-desktop-v0.9.0-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ceb76c7ac7d1f5db7b43a4ca6504644628a0848e66933ceaf4ed234de253271"
  end

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "hap-installer"
  depends_on "multica"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  # CPF-Electron Electron OHOS PC (2in1) runtime, published on GitCode.
  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/multica-desktop/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath

    # The vendor templates mix CRLF and LF. Normalize files patched below so
    # Homebrew's patch utility can match the mainElement, signingConfig, and
    # requestPermissions lines consistently.
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
    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build",
             *std_go_args(output: libexec/"multica-desktop-bridge", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica-desktop-bridge"
    end

    pkgshare.install "scripts/install-desktop-ohos.sh" => "install-desktop.sh"
    pkgshare.install "scripts/multica-desktop-ohos.sh" => "desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"desktop.sh"
    libexec.install "scripts/multica-desktop-dispatch-ohos.sh" => "multica-desktop-dispatch.sh"
    chmod 0755, libexec/"multica-desktop-dispatch.sh"
    # The daemon the bridge starts inherits this environment, and it locks its
    # per-task temp dir with flock, which /tmp refuses on OHOS.
    (bin/"multica-desktop").write_env_script libexec/"multica-desktop-dispatch.sh",
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

    # Desktop payload: the patch carried the OHOS dependency wiring
    # (pnpm overrides to @ohos-npm-ports, scoped registry, signpost dev dep).
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

    # HAP shell build. CI runs in the private electron-ohos-ci image (the
    # generic Electron-on-OHOS build image, selected via the
    # OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the HarmonyOS
    # command-line toolchain at /opt/electron-ohos-clt — repacked from a
    # licensed system CLT install, not publicly redistributable. The shell
    # compiles no C++, so the NDK-less SDK subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "multica-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['multica-desktop']"
    end

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes and the libhilog
    # stderr adapter baked into the image.
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
                    "multica-desktop-unsigned.hap"

    # The default HAP requests only what local automatic signing can grant.
    # `multica-desktop install --acl-profile` swaps in this variant, which also
    # requests the two ACL-gated permissions, for devices whose signing profile
    # carries those ACLs.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"multica-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)
  end

  def caveats
    <<~EOS
      The CLI and daemon come from the `multica` formula; this one adds the desktop.
      The desktop HAP is at #{libexec}/multica-desktop-unsigned.hap.

      The HAP is unsigned in the bottle. Connect and unlock the target device,
      then run `multica-desktop install`. hap-installer handles Huawei Developer
      login, signing-project creation, local debug profile generation, signing,
      installation, and launch. Private signing material stays in your home
      directory; it is not in the bottle.

      The default HAP requests only INTERNET and GET_NETWORK_INFO, which local
      automatic signing can grant. If your signing profile carries the
      CUSTOM_SANDBOX and READ_WRITE_USER_FILE ACLs (for example an AGC debug
      profile), run `multica-desktop install --acl-profile <build-profile.json5>`
      to sign and install a copy that also requests them; without those ACLs the
      device refuses to install it.

      The desktop app runs in an app sandbox that cannot execute the CLI or read
      ~/.multica, so a small loopback bridge runs on the host. `multica-desktop
      install` starts it and pairs it with the app; afterwards run
      `multica-desktop` to start the bridge (if needed) and open the app. Logging
      in inside the desktop app then configures and starts the daemon. To start
      only the bridge from a shell startup file, add
      `"$HOME/.harmonybrew/bin/multica-desktop" start --bridge-only`. Use the
      absolute path: a startup file can run before Homebrew's bin is on PATH,
      where a bare `multica-desktop` is not found and the line fails silently.
      `multica-desktop stop` stops the bridge and leaves the daemon running.

      Keep `multica` and `multica-desktop` on the same version; `multica-desktop`
      warns when they differ.
    EOS
  end

  test do
    require "net/http"

    ENV["HOME"] = testpath/"home"
    assert_match "Usage: multica-desktop <command>", shell_output("#{bin}/multica-desktop --help")
    assert_match "Usage: multica-desktop install", shell_output("#{bin}/multica-desktop install --help")
    launcher_help = with_env(MULTICA_DESKTOP_BRIDGE: (libexec/"multica-desktop-bridge").to_s) do
      shell_output("#{pkgshare}/desktop.sh --help")
    end
    assert_match "Usage: multica-desktop [start|stop|status]", launcher_help
    assert_match "unknown command: bogus", shell_output("#{bin}/multica-desktop bogus 2>&1", 2)
    cli = formula_opt_prefix("multica")/"libexec/multica-cli"
    cli_version = Formula["multica"].version.to_s
    # The bridge outlives `brew upgrade`, so the CLI it is told to run must be
    # the stable opt path of the multica formula, never a Cellar version directory.
    wrapper = (bin/"multica-desktop").read
    assert_match cli.to_s, wrapper
    refute_match "Cellar/multica/", wrapper
    assert_match "MULTICA_DESKTOP_VERSION=\"#{version}\"", wrapper
    # The daemon the bridge starts locks its per-task temp dir with flock, which
    # /tmp refuses on OHOS, so this wrapper must carry a usable base as well. A
    # value the user set explicitly still wins.
    temp_base = "/data/storage/el2/base/cache"
    assert_match "MULTICA_AGENT_TEMP_BASE=\"${MULTICA_AGENT_TEMP_BASE:-#{temp_base}}\"", wrapper
    env_probe = testpath/"env-probe"
    env_probe.write wrapper.sub(/exec "[^"]*multica-desktop-dispatch\.sh"/, "exec env")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{temp_base}\n",
                 shell_output("env -u MULTICA_AGENT_TEMP_BASE sh #{env_probe}")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{testpath}/custom\n",
                 shell_output("MULTICA_AGENT_TEMP_BASE=#{testpath}/custom sh #{env_probe}")
    # A shell startup file can run before Homebrew's bin is on PATH, so the
    # line the caveats suggest for it has to use the absolute path.
    assert_match "\"$HOME/.harmonybrew/bin/multica-desktop\" start --bridge-only", caveats
    assert_match "before Homebrew's bin is on PATH", caveats
    refute_match "`multica-desktop start --bridge-only`", caveats
    # The caveats must not point at a separate project repository.
    refute_match "github.com/social4hyq", caveats
    desktop_installer = pkgshare/"install-desktop.sh"
    assert_match "hap-installer", desktop_installer.read
    refute_match "devecocli", desktop_installer.read
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
    # A CLI of another version than this desktop is warned about, not refused.
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
    assert_match "Usage: multica-desktop install", mismatch
    matching = with_env(MULTICA_REAL_CLI: cli.to_s, MULTICA_DESKTOP_VERSION: cli_version,
                        MULTICA_INSTALL_DESKTOP: desktop_installer.to_s) do
      shell_output("#{libexec}/multica-desktop-dispatch.sh install --help 2>&1")
    end
    refute_match "warning", matching
    installer_args = testpath/"hap-installer-args"
    injected_hap = testpath/"injected.hap"
    fake_installer = fake_bin/"hap-installer"
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
    fake_signer = fake_bin/"hap-installer-sign"
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
      assert_equal ["--bundle-id", "com.huawei.ohos_electron", "--app-name", "MulticaSigning",
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
      # The ACL variant goes through hap-installer too, with the given profile.
      # installer_args holds one argument per line.
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

      # A bridge started from a keg that later disappears (as `brew upgrade`
      # does) must be reported stale and be replaced by `multica-desktop start`.
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
    assert_path_exists pkgshare/"install-desktop.sh"
    hap = libexec/"multica-desktop-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "module.json", listing
    assert_match "ets/modules.abc", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/out/main/index.js", listing
    refute_match "node_modules/typescript/", listing
    refute_match "node_modules/@multica/eslint-config/", listing
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_empty package.fetch("devDependencies", {})
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
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
