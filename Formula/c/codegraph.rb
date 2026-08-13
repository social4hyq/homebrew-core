class Codegraph < Formula
  desc "Pre-indexed code knowledge graph for AI coding agents — 100% local"
  homepage "https://github.com/colbymchenry/codegraph"
  url "https://github.com/colbymchenry/codegraph/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "319758918f58418a8a576d24c7829ecfa9e68eff78ddf49f52455a27a79ec621"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codegraph-v1.5.0-r3"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "6f2b282674b1f22ea0f67ebb6a65405b72884662fe18c7c99fdbde2fd48b0cc8"
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
    chmod 0755, bin/"codegraph"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codegraph --version 2>&1")
  end
end
