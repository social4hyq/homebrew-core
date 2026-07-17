class OpencodeAi < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64"
  homepage "https://github.com/social4hyq/ohos-opencode"
  url "https://github.com/social4hyq/ohos-opencode.git",
      tag:      "v1.18.3",
      revision: "44049810b225e29e140cbe2c0d0980eb6b687ca8"
  version "1.18.3"
  license "MIT"

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.3-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  end

  # opencode is a `bun build --compile` single binary with bun runtime + JS + native .node/.so
  # all embedded and pre-signed. The bottle has zero runtime dependencies.
  #
  # Native deps (bun-pty, lightningcss, @tailwindcss/oxide, @opentui/core) come from
  # @ohos-ports/* npm packages via package.json overrides aliases (loader patches ship
  # inside those packages); bun 1.4.0_26+ auto-signs .node/.so in workspace mode during
  # `bun install`. No Homebrew-keg copying or node_modules string patching needed.
  #
  # @parcel/watcher needs no handling: opencode lazy-loads it with try/catch and degrades
  # gracefully on openharmony (file watching disabled, no crash).
  depends_on "bun"         => :build
  depends_on "node"        => :build # npm_config_nodedir for bun install
  depends_on "ohos-sdk"    => :build # binary-sign-tool + llvm-objcopy (strip .codesign)
  depends_on "python@3.14" => :build

  def install
    ENV["PYTHON"] = formula_opt_bin("python@3.14")/"python3"
    ENV["npm_config_nodedir"] = formula_opt_prefix("node").to_s
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    # Persistent bun cache (buildpath is wiped each run, causing network-failed packages to be re-downloaded
    # every time; place it under HOMEBREW_CACHE).
    ENV["BUN_INSTALL_CACHE"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Remove workspace packages not needed for the CLI build.
    rm_r("packages/desktop")
    rm_r("packages/web")
    rm_r("packages/docs")
    rm_r("packages/storybook")

    system "bun", "install", "--ignore-scripts"

    # build.ts defaults to running `bun install --os=* --cpu=*` to pull all-platform native variants, but it
    # depends on Bun.$ → on OHOS, sh cannot exec bun from PATH (EPERM), so we pass --skip-install to skip the
    # internal version in build.ts and invoke it directly here, avoiding the broken $ path.
    #
    # @ohos-ports/opentui-core's loader maps openharmony-arm64 → @opentui/core-linux-arm64-musl
    # (musl ABI compatible), but bun's os filter skips linux optional deps on openharmony, so the
    # musl variant must be pulled explicitly. bun's installer auto-signs the shipped libopentui.so.
    # Version must match the @opentui/core override in package.json.
    system "bun", "install", "--os=linux", "--cpu=arm64", "@opentui/core-linux-arm64-musl@0.4.3"

    # Bun runtime symlink: Bun.build({compile: {target: "bun-linux-arm64-musl"}}) expects a local bun
    bun_runtime = buildpath/"packages/opencode/bun-linux-aarch64-musl-v1.4.0"
    ln_sf formula_opt_bin("bun")/"bun", bun_runtime

    cd "packages/opencode" do
      version = JSON.parse(File.read("package.json"))["version"]
      ENV["OPENCODE_VERSION"] = version
    end

    # 1) Pre-build the Web UI (vite → rolldown-vite)
    system "bun", "run", "--cwd", "packages/app", "build"

    # 2) bun compile + embed Web UI (SKIP_VITE_BUILD=1 skips the second vite invocation inside build.ts)
    cd "packages/opencode" do
      ENV["SKIP_VITE_BUILD"] = "1"
      system "bun", "run", "script/build.ts", "--single", "--skip-install"
    end

    # 3) Strip the embedded .codesign section, then re-sign with binary-sign-tool
    sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
    objcopy   = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-objcopy"

    out = "packages/opencode/dist/opencode-openharmony-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)
    unsigned = "#{out}.unsigned"
    stripped = "#{out}.stripped"
    mv out, unsigned
    system objcopy, "--remove-section", ".codesign", unsigned, stripped
    system sign_tool, "sign", "-selfSign", "1", "-inFile", stripped, "-outFile", out
    chmod 0755, out
    rm unsigned
    rm stripped
    bin.install out => "opencode-ai"
    # Stub xdg-open so `opencode web` can spawn it without ENOENT on OHOS.
    (bin/"xdg-open").write "#!/bin/sh\nexit 0\n"
    chmod 0755, bin/"xdg-open"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode-ai --version 2>&1")
  end
end
