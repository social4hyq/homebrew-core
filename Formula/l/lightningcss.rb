class Lightningcss < Formula
  desc "CSS parser native binding for HarmonyOS aarch64"
  homepage "https://lightningcss.dev"
  license "MPL-2.0"
  url "https://github.com/parcel-bundler/lightningcss/archive/refs/tags/v1.30.1.tar.gz"
  sha256 "234c9c3ef0d8d59252cf64f36b53f49c8ca9d937f5301e501227c08ea4b6b7fe"
  version "1.30.1"

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/lightningcss-v1.30.1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f941d3ce8aa41f2259a7281e8e45cadba0855110555d13ea4e63711df2666a42"
  end

  keg_only "consumed in-tree by opencode/vite build"
  depends_on "rust"    => :build
  depends_on "ohos-sdk"

  def install
    ENV.delete("RUSTC_WRAPPER")
    system "cargo", "build", "-p", "lightningcss_node", "--release", "--target", "aarch64-unknown-linux-ohos"
    so = "target/aarch64-unknown-linux-ohos/release/liblightningcss_node.so"
    odie "build failed" unless File.exist?(so)
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    unsigned = "#{so}.unsigned"
    mv so, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", so
    chmod 0755, so
    rm unsigned
    lib.install so => "liblightningcss_node.so"
  end

  test do
    assert_predicate lib/"liblightningcss_node.so", :exist?
  end
end
