class Lightningcss < Formula
  desc "CSS parser native binding for HarmonyOS aarch64"
  homepage "https://lightningcss.dev"
  url "https://github.com/parcel-bundler/lightningcss/archive/refs/tags/v1.30.1.tar.gz"
  version "1.30.1"
  sha256 "234c9c3ef0d8d59252cf64f36b53f49c8ca9d937f5301e501227c08ea4b6b7fe"
  license "MPL-2.0"
  # This formula deviates from upstream: it builds only the cdylib .so binding
  # (lightningcss_node) for HarmonyOS, not the full CLI package.

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/lightningcss-v1.30.1-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c54453b270011c1c10bb3700c9b41f89b1dcff5d492054b58fad3ccf58722646"
  end

  keg_only "consumed in-tree by opencode/vite build"
  depends_on "ohos-sdk" => :build # binary-sign-tool, only used during install
  depends_on "rust"     => :build

  def install
    ENV.delete("RUSTC_WRAPPER")

    system "cargo", "build", "--lib", "-p", "lightningcss_node", "--release", "--target", "aarch64-unknown-linux-ohos"

    so = "target/aarch64-unknown-linux-ohos/release/liblightningcss_node.so"
    odie "build failed" unless File.exist?(so)
    sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
    unsigned = "#{so}.unsigned"
    mv so, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", so
    chmod 0755, so
    rm unsigned
    lib.install so => "liblightningcss_node.so"
  end

  test do
    assert_path_exists lib/"liblightningcss_node.so"
  end
end
