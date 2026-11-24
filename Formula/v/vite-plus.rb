class VitePlus < Formula
  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v1.8.0.tar.gz"
  sha256 "f4ed3acae98b31d2be0bd29f2ccfd61e24dfeb1f03166be22946f48d72c904ce"
  license "MIT"
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v1.8.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cac5abb04eb72aabb94ad3a0ed2d9af0ea8d4e41d72436b22f25655162446790"
  end

  depends_on "cmake" => :build
  depends_on "just" => :build
  depends_on "pkgconf" => :build
  depends_on "pnpm" => :build
  depends_on "rust" => :build
  depends_on "node"
  depends_on "sqlite" unless OS.ohos?

  resource "rolldown" do
    url "https://github.com/rolldown/rolldown.git",
        revision: "b9c75ddc8bd50f2c1a4c7be0b548bdab5cba85ab"
    version "b9c75ddc8bd50f2c1a4c7be0b548bdab5cba85ab"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("rolldown", "hash")
      end
    end
  end

  resource "vite" do
    url "https://github.com/vitejs/vite.git",
        revision: "b39e6e63dcbfc3cf4be871acf3554efbd6d0e268"
    version "b39e6e63dcbfc3cf4be871acf3554efbd6d0e268"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("vite", "hash")
      end
    end
  end

  resource "oxc-node" do
    url "https://github.com/oxc-project/oxc-node.git",
        revision: "16c0f340aebd927b72d941b693e51dd6f5264f17"
    version "16c0f340aebd927b72d941b693e51dd6f5264f17"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("oxc-node", "hash")
      end
    end
  end

  if OS.ohos?
    # @napi-rs/cli cross-compiles the bundled bindings against the SDK.
    depends_on "ohos-sdk-native" => :build

    patch_root = Pathname(__dir__).parent.parent

    resource "vite-task-src" do
      url "https://github.com/voidzero-dev/vite-task.git",
          revision: "6a23096aa2f04eb59225c6467b15c2965ee6ae33"
      version "6a23096aa2f04eb59225c6467b15c2965ee6ae33"

      Dir[(patch_root/"Patches/vite-plus/vite-task/*.patch").to_s].each do |path|
        patch :p1 do
          file Pathname(path).relative_path_from(patch_root).to_s
        end
      end
    end

    Dir[(patch_root/"Patches/vite-plus/ohos/*.patch").to_s].each do |path|
      patch :p1 do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"
    resource("oxc-node").stage buildpath/"oxc-node"

    # Apply Vite+'s branding and config patches to the staged Vite source, as upstream `sync-remote` does
    system "node", "packages/tools/src/index.ts", "brand-vite"

    # Any Node.js may load the binding, so on OHOS sqlite stays bundled in it
    ENV["LIBSQLITE3_SYS_USE_PKG_CONFIG"] = "1" unless OS.ohos?
    ENV["RUSTC_BOOTSTRAP"] = "1" # workaround to build with stable rust

    # Build with Homebrew pnpm. The staged resources pin their own versions too
    %w[package.json rolldown/package.json vite/package.json].each do |file|
      package_json = buildpath/file
      package_json.atomic_write(JSON.pretty_generate(JSON.parse(package_json.read).except("packageManager")))
    end

    # Point the vendored oxc-node at the workspace's oxc version, as upstream CI does
    system "node", "packages/tools/src/patch-oxc-node.ts"

    # Align the staged Vite's Vitest versions with the lockfile, as upstream CI does
    system "node", "packages/tools/src/vendored-vitest.ts"

    # Vite patches only build-time dependencies, which the production deploy below omits
    (buildpath/"pnpm-workspace.yaml").append_lines "allowUnusedPatches: true"

    if OS.ohos?
      # @napi-rs/cli builds the ohos linker/cc/ar paths from this.
      ENV["OHOS_SDK_NATIVE"] = formula_opt_prefix("ohos-sdk-native").to_s

      # Patch 0005 points fspy at this checkout, at ../vite-task.
      resource("vite-task-src").stage buildpath.parent/"vite-task"
    end

    system "just", "build"
    system "cargo", "test", "-p", "vp_js_runtime", "-p", "vp_pm_cli" if OS.ohos?
    system "cargo", "install", *std_cargo_args(path: "crates/vp_global_cli")

    deploy_args = %w[--prod --legacy]
    # --no-optional would drop the oxfmt and oxlint openharmony bindings
    deploy_args << "--no-optional" unless OS.ohos?
    system "pnpm", "--filter=vite-plus", "deploy", *deploy_args,
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    # Remove incompatible pre-built `bare-*` binaries. Recurse as `deploy --legacy` writes
    # both the legacy `<name>@<version>` and the current `@/<name>/<version>/<hash>` layouts
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob(".pnpm/**/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }
    rm_r node_modules.glob(".pnpm/**/node_modules/fsevents")

    # Symlink vp to vpr and vpx. These are detected at runtime by argv[0]
    bin.install_symlink bin/"vp" => "vpr"
    bin.install_symlink bin/"vp" => "vpx"

    # Generate shell completions, vp uses clap but with a custom env var so we can't use our helper
    (bash_completion/"vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "bash" }, bin/"vp")
    (fish_completion/"vp.fish").write Utils.safe_popen_read({ "VP_COMPLETE" => "fish" }, bin/"vp")
    (zsh_completion/"_vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "zsh" }, bin/"vp")
  end

  def caveats
    <<~EOS
      On OpenHarmony, a managed Node.js is downloaded from the community mirror
      ohos-node.com, as nodejs.org has no OpenHarmony builds. Downloads are checked
      against SHASUMS256.txt and its signature when the mirror provides one.
      To use another mirror:
        export VP_NODE_DIST_MIRROR=https://example.com/dist
    EOS
  end

  test do
    # Use Homebrew node and skip the first-run setup prompt, which stops `vp` on the test PTY
    ENV["VP_NODE_MANAGER"] = "no"

    assert_match version.to_s, shell_output("#{bin}/vp --version")

    # `vp` calls `tcsetattr` on a tty stdin, which stops it with SIGTTOU on the test PTY
    system "#{bin}/vp create vite:application --no-interactive --directory test-app < /dev/null"
    assert_path_exists testpath/"test-app/package.json"

    if OS.ohos?
      # The scaffolded app installs vite-plus from npm, which has no openharmony binding.
      (testpath/"format").mkpath
      (testpath/"format/package.json").write '{"private":true}'
      (testpath/"format/index.js").write "const answer = 42\n"
      cd testpath/"format" do
        output = shell_output("#{bin}/vp fmt index.js < /dev/null")
        assert_match "Finished", output
      end
    else
      cd testpath/"test-app" do
        output = shell_output("#{bin}/vp fmt < /dev/null")
        assert_match "Finished", output
      end
    end
  end
end
