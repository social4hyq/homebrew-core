class Codegraph < Formula
  desc "Pre-indexed code knowledge graph for AI coding agents — 100% local"
  homepage "https://github.com/colbymchenry/codegraph"
  url "https://github.com/colbymchenry/codegraph/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "9b264c584395e69595d0b8c602a7f5c65a19d16a26673953721829f32cfda119"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "673ca8444524d1e57f3bf52f510d63a3b269cf524bd31bd84ba10098908c63e4"
  end

  depends_on "rust" => :build
  depends_on "node@24"

  def install
    system "npm", "install", *std_npm_args(prefix: false)
    system "npm", "run", "build"

    cd "codegraph-kernel" do
      system "cargo", "build", "--release", "--lib", "--locked"
      mkdir_p "prebuilds/openharmony-arm64"
      cp "target/release/libcodegraph_kernel.so", "prebuilds/openharmony-arm64/codegraph-kernel.node"
    end

    libexec.install "dist"
    libexec.install "node_modules"
    libexec.install "package.json"
    (libexec/"kernel").install "codegraph-kernel/prebuilds/openharmony-arm64/codegraph-kernel.node"

    # CODEGRAPH_KERNEL_PATH bypasses the loader's platform path search
    # (process.platform is 'openharmony', not 'linux'); --liftoff-only avoids a
    # V8 turboshaft WASM OOM with tree-sitter grammars.
    (bin/"codegraph").write_env_script(
      formula_opt_bin("node@24")/"node",
      ["--liftoff-only", "--disable-warning=ExperimentalWarning", opt_libexec/"dist/bin/codegraph.js"],
      "CODEGRAPH_KERNEL_PATH" => opt_libexec/"kernel/codegraph-kernel.node",
    )
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codegraph --version 2>&1")
  end
end
