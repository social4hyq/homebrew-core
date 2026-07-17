class OpencodeAi < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.3.tar.gz"
  sha256 "494041aedd7407079f91fd694de355f4ff022ba6bf876e09ff30983bbdc70ae1"
  license "MIT"

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-ai-v1.18.3-r1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ee0c8549445e5c9430a26000b5dc0aea068fba60c74bb399ea633ef301a9c40"
  end

  # opencode is a `bun build --compile` single binary: OHOS bun runtime + JS
  # bundle + native .so all embedded. The bottle has zero runtime dependencies.
  #
  # Native deps come from @ohos-ports/* npm packages via package.json override
  # aliases (see Patches/opencode-ai/ohos-ports-deps.patch): opentui-core
  # (bundled musl libopentui.so via file-loader import, 0.4.4+), bun-pty,
  # lightningcss, tailwindcss-oxide. bun signs extracted .node/.so in-process
  # during `bun install`, and `bun build --compile` re-signs its output ELF
  # (bun.rb r16+), so no external signing pass is needed here — install()
  # asserts the .codesign section is present instead.
  #
  # `bun install --ignore-scripts` is intentional: lifecycle scripts are
  # irrelevant to signing, and tree-sitter-bash/-powershell (in
  # trustedDependencies) would fall back to a node-gyp source build on
  # openharmony (no prebuilds) for native bindings the app never loads —
  # opencode uses web-tree-sitter (wasm) at runtime.
  #
  # @parcel/watcher needs no handling: opencode lazy-loads it with try/catch
  # and degrades gracefully on openharmony (file watching disabled, no crash).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # OHOS adaptations, mirrored from social4hyq/ohos-opencode dev (patches are
  # the `git diff v1.18.3..dev` for the respective files — regenerate there,
  # never hand-edit hunks).
  patch :p1 do
    file "Patches/opencode-ai/ohos-ports-deps.patch"
  end
  patch :p1 do
    file "Patches/opencode-ai/build-ohos-target.patch"
  end
  patch :p1 do
    file "Patches/opencode-ai/project-global-worktree.patch"
  end
  patch :p1 do
    file "Patches/opencode-ai/web-open-try-catch.patch"
  end

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    # Persistent bun cache: buildpath is wiped each run, which would re-download
    # every package after a network hiccup. (The env var is BUN_INSTALL_CACHE_DIR;
    # BUN_INSTALL_CACHE is a no-op.)
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron etc. from
    # the install set entirely).
    rm_r("packages/desktop")
    rm_r("packages/web")
    rm_r("packages/docs")
    rm_r("packages/storybook")

    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git / registry
    # lookup), which also flips Script.channel to "latest".
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts (patched) self-materializes the compile runtime from
    # process.execPath (the real OHOS bun ELF, even under the brew LD_PRELOAD
    # wrapper) and picks the openharmony-arm64-musl target under --single.
    #
    # No --skip-install: build.ts's internal `bun install --os="*" --cpu="*"`
    # passes are required here. bun's bundler hard-errors on imports of
    # platform packages matching the compile target (linux-arm64-musl), and
    # the openharmony install filter skips exactly those (fff-bun, opentui,
    # parcel-watcher variants are all os-gated to linux/darwin/win32).
    cd "packages/opencode" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/opencode/dist/opencode-openharmony-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)

    # The device kernel refuses to exec unsigned ELFs; bun's compile step must
    # have produced a .codesign section (ohos_sign, bun.rb r16+).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    bin.install out => "opencode-ai"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode-ai --version 2>&1")
  end
end
