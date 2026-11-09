class Multica < Formula
  desc "CLI, local daemon and desktop GUI for the Multica AI agent workspace"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "4d142f4d676f90576dcf71787d3b9d20f6ec5329e0f3a8db14364cdc90253ad2"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)
  revision 8

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-v0.8.1-r11"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7ea06300aa380572ea72a83b98780f93aa06cff276cdb382036ac9baddee612a"
  end

  depends_on "go" => :build
  depends_on "node"
  depends_on "ohos-sdk-toolchains"

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
    file "Patches/multica/0003-add-sign-hap-helper.patch"
  end

  patch :p1 do
    file "Patches/multica/0004-install-desktop-command.patch"
  end

  patch :p1 do
    file "Patches/multica/0005-default-signing-paths.patch"
  end

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath
    super
  end

  def install
    cli_source = buildpath/"tools/deveco-cli"
    system "npm", "ci", "--prefix", cli_source,
           "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    inreplace cli_source/"node_modules/axios/lib/adapters/http.js",
              "throw new AxiosError('Invalid proxy authorization', AxiosError.ERR_BAD_OPTION, { proxy });",
              "proxyAuth = false;"
    libexec.install cli_source/"node_modules"
    cli_js = libexec/"node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js"
    chmod 0755, cli_js
    bin.install_symlink libexec/"node_modules/.bin/devecocli" => "devecocli"

    toolchain = libexec/"deveco-signing-toolchain"
    toolchain.mkpath
    toolchain_node = toolchain/"node/bin/node"
    toolchain_node.dirname.mkpath
    toolchain_node.write_env_script formula_opt_bin("node")/"node", {}
    ohpm_entry = toolchain/"ohpm/bin/pm-cli.js"
    ohpm_entry.dirname.mkpath
    ohpm_entry.write <<~JS
      console.error("This command-line toolchain adapter supports signing only.");
      process.exit(1);
    JS
    hvigor_entry = toolchain/"hvigor/bin/hvigorw.js"
    hvigor_entry.dirname.mkpath
    hvigor_entry.write <<~JS
      console.error("This command-line toolchain adapter supports signing only.");
      process.exit(1);
    JS
    sdk = toolchain/"sdk/default/openharmony"
    sdk_tools = formula_opt_prefix("ohos-sdk-toolchains")
    sdk_metadata = sdk/"toolchains/oh-uni-package.json"
    sdk_metadata.dirname.mkpath
    cp sdk_tools/"oh-uni-package.json", sdk_metadata
    sdk_info = JSON.parse(sdk_metadata.read)
    (toolchain/"sdk/default/sdk-pkg.json").write JSON.generate("data" => sdk_info)
    (sdk/"toolchains/hdc").write_env_script sdk_tools/"hdc", {}
    signer = sdk/"toolchains/lib/hap-sign-tool"
    signer.dirname.mkpath
    signer.write_env_script sdk_tools/"lib/hap-sign-tool", {}

    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build", *std_go_args(output: libexec/"multica-cli", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica"
    end

    pkgshare.install "scripts/install-hap-ohos.sh" => "install-hap.sh"
    pkgshare.install "scripts/install-desktop-ohos.sh" => "install-desktop.sh"
    pkgshare.install "scripts/sign-hap.cjs" => "multica-sign-hap"
    chmod 0755, pkgshare/"install-hap.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"multica-sign-hap"
    bin.install_symlink pkgshare/"multica-sign-hap" => "multica-sign-hap"
    libexec.install "scripts/multica-dispatch-ohos.sh" => "multica-dispatch.sh"
    chmod 0755, libexec/"multica-dispatch.sh"
    (bin/"multica").write_env_script libexec/"multica-dispatch.sh",
      COMMAND_LINE_TOOL_PATH:  toolchain,
      DEVECO_CLI_JS:           cli_js,
      HAP_SIGN_TOOL:           sdk_tools/"lib/hap-sign-tool",
      MULTICA_INSTALL_DESKTOP: pkgshare/"install-desktop.sh",
      MULTICA_INSTALLER:       pkgshare/"install-hap.sh",
      MULTICA_REAL_CLI:        libexec/"multica-cli",
      MULTICA_SIGNER:          pkgshare/"multica-sign-hap",
      MULTICA_UNSIGNED_HAP:    libexec/"multica-desktop-unsigned.hap",
      PATH:                    "#{formula_opt_bin("node")}:#{sdk_tools}:$PATH"
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
  end

  def caveats
    <<~EOS
      The CLI and daemon are available as `multica`.
      The desktop HAP is at #{libexec}/multica-desktop-unsigned.hap.

      The HAP is unsigned in the bottle. Connect and unlock the target device,
      then run `multica install-desktop`. On first use it opens DevEco CLI's
      Huawei Developer account login, creates the signing project, generates
      device-bound debug materials, signs the HAP, installs it, and starts it.
      Private signing material stays in your home directory; it is not in the
      bottle. The packaged DevEco CLI toolchain adapter is for signature
      generation only; it does not provide general-purpose HAP builds.

      The full flow (signing config shape, daemon pairing, supervisor) is
      documented in the ohos-multica project: Build Pipeline and Distribution
      guides at https://github.com/social4hyq/ohos-multica .
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "multica #{version}", shell_output("#{bin}/multica --version")
    assert_match "CORE COMMANDS", shell_output("#{bin}/multica --help")
    assert_match "Usage: multica install-desktop", shell_output("#{bin}/multica install-desktop --help")
    assert_match "Authentication commands", shell_output("#{bin}/devecocli auth --help")
    assert_path_exists pkgshare/"install-hap.sh"
    assert_predicate pkgshare/"install-hap.sh", :executable?
    sdk_info = JSON.parse((libexec/"deveco-signing-toolchain/sdk/default/sdk-pkg.json").read)
    assert_match(/\A\d+\z/, sdk_info.fetch("data").fetch("apiVersion").to_s)
    assert_path_exists pkgshare/"install-desktop.sh"
    assert_path_exists pkgshare/"multica-sign-hap"
    assert_match "Usage: sign-hap.cjs", shell_output("#{bin}/multica-sign-hap --help")
    axios = libexec/"node_modules/axios"
    assert_match(/else if \(authIsObject\) \{\s+proxyAuth = false;/,
                 (axios/"lib/adapters/http.js").read)
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
    assert_equal %w[@electron-toolkit/utils electron-updater], package.fetch("dependencies").keys.sort
    system "unzip", "-tq", hap
  end
end
