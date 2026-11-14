class Multica < Formula
  desc "CLI, local daemon and desktop GUI for the Multica AI agent workspace"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "c52ffa09412bfc0f6cd6bed0900a66252b1c30f355f257f991a62a88e121eac8"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)
  revision 4

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-v0.9.0-r7"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6f701781d8a4b9783ef7ce8550398128b0f30d1e35f16c2a23c765b8e63d911"
  end

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "hap-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see release notes).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  patch :p1 do
    file "Patches/multica/0001-desktop-ohos.patch"
  end

  patch :p1 do
    file "Patches/multica/0002-hap-packaging.patch"
  end

  patch :p1 do
    file "Patches/multica/0004-install-desktop-command.patch"
  end

  patch :p1 do
    file "Patches/multica/0005-desktop-host-bridge.patch"
  end

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath
    super
  end

  def install
    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build", *std_go_args(output: libexec/"multica-cli", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica"
      system "go", "build",
             *std_go_args(output: libexec/"multica-desktop-bridge", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica-desktop-bridge"
    end

    pkgshare.install "scripts/install-hap-ohos.sh" => "install-hap.sh"
    pkgshare.install "scripts/install-desktop-ohos.sh" => "install-desktop.sh"
    pkgshare.install "scripts/multica-desktop-ohos.sh" => "desktop.sh"
    chmod 0755, pkgshare/"install-hap.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"desktop.sh"
    libexec.install "scripts/multica-dispatch-ohos.sh" => "multica-dispatch.sh"
    chmod 0755, libexec/"multica-dispatch.sh"
    (bin/"multica").write_env_script libexec/"multica-dispatch.sh",
      MULTICA_DESKTOP:         pkgshare/"desktop.sh",
      MULTICA_DESKTOP_BRIDGE:  libexec/"multica-desktop-bridge",
      MULTICA_HDC:             formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      MULTICA_INSTALL_DESKTOP: pkgshare/"install-desktop.sh",
      MULTICA_INSTALL_HAP:     pkgshare/"install-hap.sh",
      MULTICA_MODULE_ACL:      pkgshare/"module-acl.json",
      MULTICA_REAL_CLI:        libexec/"multica-cli",
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
    # licensed system CLT install, not publicly redistributable (see the
    # ohos-multica project). The shell compiles no C++, so the NDK-less SDK
    # subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "multica builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['multica']" unless
      (clt/"hvigor/bin/hvigorw.js").exist?

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
    # `multica install-desktop --acl-profile` swaps in this variant, which also
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
      The CLI and daemon are available as `multica`.
      The desktop HAP is at #{libexec}/multica-desktop-unsigned.hap.

      The HAP is unsigned in the bottle. Connect and unlock the target device,
      then run `multica install-desktop`. hap-installer handles Huawei Developer
      login, signing-project creation, local debug profile generation, signing,
      installation, and launch. Private signing material stays in your home
      directory; it is not in the bottle.

      The default HAP requests only INTERNET and GET_NETWORK_INFO, which local
      automatic signing can grant. If your signing profile carries the
      CUSTOM_SANDBOX and READ_WRITE_USER_FILE ACLs (for example an AGC debug
      profile), run `multica install-desktop --acl-profile <build-profile.json5>`
      to sign and install a copy that also requests them; without those ACLs the
      device refuses to install it.

      The desktop app runs in an app sandbox that cannot execute the CLI or read
      ~/.multica, so a small loopback bridge runs on the host. `multica
      install-desktop` starts it and pairs it with the app; afterwards run
      `multica desktop` to start the bridge (if needed) and open the app. Logging
      in inside the desktop app then configures and starts the daemon. To start
      only the bridge from a shell startup file, use
      `multica desktop start --bridge-only`; `multica desktop stop` stops it and
      leaves the daemon running.

      The full flow (signing config shape, bridge pairing) is documented in the
      ohos-multica project: Build Pipeline and Distribution guides at
      https://github.com/social4hyq/ohos-multica .
    EOS
  end

  test do
    require "net/http"

    ENV["HOME"] = testpath/"home"
    assert_match "multica #{version}", shell_output("#{bin}/multica --version")
    assert_match "CORE COMMANDS", shell_output("#{bin}/multica --help")
    assert_match "Usage: multica install-desktop", shell_output("#{bin}/multica install-desktop --help")
    assert_match "Usage: multica desktop", shell_output("#{bin}/multica desktop --help")
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
    ENV["MULTICA_REAL_CLI"] = (libexec/"multica-cli").to_s
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
    acl_install_args = testpath/"install-hap-args"
    fake_hap_install = fake_bin/"install-hap"
    fake_hap_install.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{acl_install_args}
    SH
    chmod 0755, fake_hap_install
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

      ENV["MULTICA_INSTALL_HAP"] = fake_hap_install.to_s
      ENV["MULTICA_MODULE_ACL"] = (pkgshare/"module-acl.json").to_s
      (testpath/"build-profile.json5").write "{}"
      shell_output("#{desktop_installer} --acl-profile #{testpath}/build-profile.json5")
      assert_match "--profile #{testpath}/build-profile.json5", signer_args.read
      assert_equal ["--start"], acl_install_args.read.lines(chomp: true).drop(1)
      signed_module = JSON.parse(shell_output("unzip -p #{signer_input} module.json"))
      signed_permissions = signed_module.fetch("module").fetch("requestPermissions").map do |permission|
        permission.fetch("name")
      end
      assert_includes signed_permissions, "ohos.permission.CUSTOM_SANDBOX"
      assert_includes signed_permissions, "ohos.permission.READ_WRITE_USER_FILE"
      assert_equal pairing.read,
                   shell_output("unzip -p #{signer_input} resources/resfile/resources/app/desktop-bridge.json")

      paired = JSON.parse(pairing.read)
      base = URI("http://127.0.0.1:#{paired.fetch("port")}")
      assert_match '"ok":true', Net::HTTP.get(base + "/health")
      body = JSON.generate("args" => ["version", "--output", "json"])
      denied = Net::HTTP.post(base + "/exec", body, "Content-Type" => "application/json")
      assert_equal "401", denied.code
      allowed = Net::HTTP.post(base + "/exec", body, "Content-Type"  => "application/json",
                                                     "Authorization" => "Bearer #{paired.fetch("secret")}")
      assert_equal "200", allowed.code
      assert_match version.to_s, JSON.parse(allowed.body).fetch("stdout")
    ensure
      system pkgshare/"desktop.sh", "stop"
    end
    refute_path_exists libexec/"node_modules"
    assert_path_exists pkgshare/"install-hap.sh"
    assert_predicate pkgshare/"install-hap.sh", :executable?
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
