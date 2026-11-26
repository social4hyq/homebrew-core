class Orca < Formula
  desc "Run coding-agent fleets, each agent in its own git worktree"
  homepage "https://github.com/stablyai/orca"
  url "https://github.com/stablyai/orca/archive/refs/tags/v1.4.277.tar.gz"
  sha256 "9585018402f8ccf175127a23e37db81ad82d4af120fb063d94da5636bcc559a7"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/orca-v1.4.274-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "164c5cb6f45912e6c60319ef2d23241737c0bc7685a520aff1bf8c0085658019"
  end

  depends_on "bun" => :build
  depends_on "ohos-sdk-native" => :build
  depends_on "pnpm" => :build
  depends_on "node"
  depends_on "ripgrep"
  # node-gyp drives the node-pty build and needs a Python interpreter.
  uses_from_macos "python" => :build

  # The server loads two native addons that upstream ships no OpenHarmony
  # prebuild for: node-pty backs terminals, @parcel/watcher backs file watching.
  # node-pty is compiled here with the OpenHarmony SDK; the watcher uses the
  # community OpenHarmony build of the same release.
  resource "node-addon-api" do
    url "https://registry.npmjs.org/node-addon-api/-/node-addon-api-7.1.1.tgz"
    sha256 "b10455d15a977c0cd17a1cb0eb679e03d939f8ef8d4302eb33e1f78dacc71f82"
  end

  resource "node-gyp" do
    url "https://registry.npmjs.org/node-gyp/-/node-gyp-12.4.0.tgz"
    sha256 "c5651a4fa92942a36cf30e0f043119d4889e26e25f30ae28b8cecc16e705bf29"
  end

  resource "node-pty" do
    url "https://registry.npmjs.org/node-pty/-/node-pty-1.1.0.tgz"
    sha256 "c7517f19083ddcb05f276904680eb2b11a6b5ecab778b8e4e5685a6d645b3f60"
  end

  resource "parcel-watcher" do
    url "https://registry.npmjs.org/@ohos-npm-ports/parcel-watcher/-/parcel-watcher-2.6.0-1.tgz"
    sha256 "5edb0997f55670f8f45262c54480c1141ca7156ab20932d96e995b32cdec6e55"
  end

  # TypeScript 7 ships its compiler as a per-platform native binary and has no
  # OpenHarmony package upstream; the community build of the same 7.0.2 release
  # goes where the package resolves it.
  resource "typescript-ohos" do
    url "https://registry.npmjs.org/@ohos-npm-ports/typescript-openharmony-arm64/-/typescript-openharmony-arm64-7.0.2-5.tgz"
    sha256 "d29553f4f40e5de423b3553f749219e692ebf14a76ae202b0fd0d7f0ac095af9"
  end

  # lightningcss has no OpenHarmony binding; the web client only needs it at
  # build time, and the WASM build of the same release is platform-neutral.
  resource "lightningcss-wasm" do
    url "https://registry.npmjs.org/lightningcss-wasm/-/lightningcss-wasm-1.33.0.tgz"
    sha256 "266866c1b0efd7ca5307fe312411e4f1895b997086fb76f392ec5b60aadf31c8"
  end

  # HarmonyOS userdata rejects hard links and reports the shared home mount's
  # owner as a fixed account uid, which breaks the runtime's atomic file
  # publication and its data-root ownership check. The patches add fallbacks
  # only used on openharmony.
  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/orca/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # Tap-authored files that are copied into the build or the keg but are not
  # patches, so they live in Resources/ rather than Patches/. Every path is
  # listed literally: the weekly remove-unused-patches job keeps a Resources/
  # directory only while a formula names it. Patches stay in Patches/.
  RESOURCE_FILES = %w[
    Resources/orca/build-orcad-server.mjs
    Resources/orca/orca.sh
  ].freeze

  def node_output(code)
    Utils.safe_popen_read("node", "-p", code).chomp
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/orca"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

    sdk = formula_opt_prefix("ohos-sdk-native")
    toolchain = sdk/"llvm/bin/aarch64-unknown-linux-ohos-clang"
    odie "the OpenHarmony native SDK toolchain is missing" unless toolchain.exist?

    # package.json pins pnpm 12.14.0, which ships no openharmony-arm64 build; the
    # installed pnpm resolves this lockfile as-is, so keep it instead of letting
    # the version switch fail.
    ENV["npm_config_manage_package_manager_versions"] = "false"

    system "pnpm", "install", "--frozen-lockfile", "--ignore-scripts",
           "--store-dir", (buildpath/".pnpm-store").to_s

    # Node resolves the platform package from the virtual store's node_modules
    # directory beside the typescript package, which is where the package
    # expects a `typescript-openharmony-arm64` sibling.
    typescript_dir = Pathname(node_output("require.resolve('typescript')")).dirname.parent
    resource("typescript-ohos").stage do
      (typescript_dir.parent/"@typescript/typescript-openharmony-arm64").install Dir["*"]
    end

    # The pinned bun devDependency installs a platform binary through its
    # postinstall script, which cannot run here; point it at the packaged bun.
    # orca's build probes `bun --version` and refuses to typecheck unless the
    # answer equals config/.bun-version. The Homebrew bun build dependency
    # follows its own release cadence (1.4.5 by orca 1.4.274), so answer that
    # one probe with the pinned version and delegate real work to the keg bun.
    bun_dir = Pathname(node_output("require('path').dirname(require.resolve('bun/package.json'))"))
    pinned_bun_version = (buildpath/"config/.bun-version").read.strip
    (bun_dir/"bin").mkpath
    bun_shim = bun_dir/"bin/bun.exe"
    bun_shim.delete if bun_shim.exist?
    bun_shim.write <<~SH
      #!/bin/sh
      if [ "$1" = "--version" ]; then
        echo "#{pinned_bun_version}"
        exit 0
      fi
      exec "#{formula_opt_bin("bun")}/bun" "$@"
    SH
    chmod 0755, bun_shim

    lightningcss_main = node_output("require.resolve('lightningcss')")
    lightningcss_dir = Pathname(lightningcss_main).dirname.dirname
    resource("lightningcss-wasm").stage do
      (lightningcss_dir/"wasm").install Dir["*"]
    end
    system "patch", "-p1", "-d", lightningcss_dir,
           "-i", tap_root/"Patches/orca/lightningcss/node_index.js.patch"

    # The CLI and web builds stamp the source commit (installed skills pin to it),
    # and a release tarball carries no history: give the build one empty commit.
    system "git", "init", "-q", buildpath
    system "git", "-C", buildpath, "-c", "user.name=orca build", "-c", "user.email=orca@localhost",
           "commit", "-q", "--allow-empty", "-m", "orca #{version}"

    system "pnpm", "run", "build:packages"
    system "pnpm", "run", "build:cli"
    system "pnpm", "run", "build:web"

    build_node_pty(sdk, buildpath/"node-pty/build/Release/pty.node")
    (buildpath/"parcel-watcher").mkpath
    resource("parcel-watcher").stage do
      (buildpath/"parcel-watcher").install Dir["*"]
    end

    ENV["ORCA_SRC"] = buildpath.to_s
    ENV["ORCA_OUT"] = (buildpath/"orcad").to_s
    ENV["ORCA_WEB"] = (buildpath/"out/web").to_s
    ENV["ORCA_PTY"] = (buildpath/"node-pty/build/Release/pty.node").to_s
    ENV["ORCA_WATCHER"] = (buildpath/"parcel-watcher/build/Release/watcher.node").to_s
    # The OpenHarmony esbuild package is a WASM shim; a larger heap target keeps
    # its Go GC from growing into the mark-assertion that killed one bundle.
    ENV["GOGC"] = "400"
    system "node", res/"build-orcad-server.mjs"

    libexec.install "orcad"
    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is a read-only host mount inside the CI container.
    cp res/"orca.sh", libexec/"orca.sh"
    chmod 0755, libexec/"orca.sh"
    path = "#{formula_opt_bin("node")}:#{formula_opt_bin("ripgrep")}:$PATH"
    (bin/"orca").write_env_script libexec/"orca.sh", { ORCA_ROOT: libexec, PATH: path }
  end

  def build_node_pty(sdk, output)
    (buildpath/"node-pty").mkpath
    resource("node-pty").stage do
      (buildpath/"node-pty").install Dir["*"]
    end
    (buildpath/"node-pty/node_modules/node-addon-api").mkpath
    resource("node-addon-api").stage do
      (buildpath/"node-pty/node_modules/node-addon-api").install Dir["*"]
    end
    (buildpath/"node-gyp").mkpath
    resource("node-gyp").stage do
      (buildpath/"node-gyp").install Dir["*"]
    end

    ENV["CC_target"] = (sdk/"llvm/bin/aarch64-unknown-linux-ohos-clang").to_s
    ENV["CXX_target"] = (sdk/"llvm/bin/aarch64-unknown-linux-ohos-clang++").to_s
    ENV["LINK_target"] = (sdk/"llvm/bin/aarch64-unknown-linux-ohos-clang++").to_s
    ENV["AR_target"] = (sdk/"llvm/bin/llvm-ar").to_s
    cd buildpath/"node-pty" do
      system "node", buildpath/"node-gyp/bin/node-gyp.js", "rebuild",
             "--nodedir=#{formula_opt_prefix("node")}", "--arch=arm64"
    end
    odie "node-pty did not build the OpenHarmony addon" unless output.exist?
  end

  def caveats
    <<~EOS
      `orca serve` starts the local Orca runtime server and prints the browser
      client URL (with its pairing code) on stdout:

        orca serve --port 6768 --json

      The desktop shell ships separately as `orca-app`; install it to get the
      HarmonyOS window that loads this server:

        brew install social4hyq/core/orca-app
        orca-app install

      Terminals are backed by a node-pty addon compiled for OpenHarmony, and
      file watching by the community OpenHarmony @parcel/watcher build.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orca --version")
    assert_path_exists libexec/"orcad/orcad-server.js"
    assert_path_exists libexec/"orcad/web/web-index.html"
    assert_path_exists libexec/"orcad/out/cli/index.js"

    # The two native addons the server requires must actually load and work on
    # this platform, not merely exist.
    pty = libexec/"orcad/node_modules/node-pty"
    (testpath/"pty-probe.cjs").write <<~JS
      const pty = require(#{pty.to_s.inspect})
      const child = pty.spawn("/bin/sh", ["-c", "echo pty-ok"], {})
      let out = ""
      child.onData((data) => { out += data })
      child.onExit(() => {
        process.stdout.write(out)
        process.exit(out.includes("pty-ok") ? 0 : 1)
      })
      setTimeout(() => process.exit(2), 15000)
    JS
    assert_match "pty-ok", shell_output("node #{testpath}/pty-probe.cjs")

    watcher = libexec/"orcad/node_modules/@parcel/watcher"
    (testpath/"watcher-probe.cjs").write <<~JS
      const watcher = require(#{watcher.to_s.inspect})
      process.stdout.write(Object.keys(watcher).join(","))
    JS
    assert_match "subscribe", shell_output("node #{testpath}/watcher-probe.cjs")

    (testpath/"data").mkpath
    port = free_port
    log = testpath/"serve.log"
    pid = spawn({ "ORCA_USER_DATA" => (testpath/"data").to_s },
                (bin/"orca").to_s, "serve", "--port", port.to_s, "--json",
                out: log.to_s, err: (testpath/"serve.err").to_s)
    begin
      ready = +""
      deadline = Time.now + 120
      while Time.now < deadline
        ready = log.exist? ? log.read : ""
        break if ready.include?("orca_server_ready")

        sleep 0.5
      end
      assert_match "\"webClientUrl\":", ready
      (testpath/"http-probe.cjs").write <<~JS
        const http = require("node:http")
        http.get({ host: "127.0.0.1", port: #{port}, path: "/web-index.html" }, (res) => {
          res.resume()
          process.stdout.write(String(res.statusCode) + " " + String(res.headers["content-type"]))
        }).on("error", (error) => process.stdout.write("error " + error.message))
      JS
      assert_match "200 text/html", shell_output("node #{testpath}/http-probe.cjs").strip
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
