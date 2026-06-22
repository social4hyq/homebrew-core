class TailwindcssOxide < Formula
  desc "Tailwind CSS v4 native engine binding for HarmonyOS aarch64"
  homepage "https://tailwindcss.com"
  license "MIT"
  url "https://github.com/tailwindlabs/tailwindcss/archive/refs/tags/v4.1.11.tar.gz"
  sha256 "149b7db8417a4a0419ada1d2dc428a11202fc6b971f037b7a8527371c59e0cae"
  version "4.1.11"

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/tailwindcss-oxide-v4.1.11"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ce2e68589cbca2d84c1d47385e7b2c4d35186c1ce1e124e06bbd35ae53cf5eb"
  end

  keg_only "consumed in-tree by opencode/vite build"
  depends_on "rust"    => :build
  depends_on "ohos-sdk"

  def install
    ENV.delete("RUSTC_WRAPPER")
    system "cargo", "build", "-p", "tailwind-oxide", "--release", "--target", "aarch64-unknown-linux-ohos"
    so = "target/aarch64-unknown-linux-ohos/release/libtailwind_oxide.so"
    odie "build failed" unless File.exist?(so)
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    unsigned = "#{so}.unsigned"
    mv so, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", so
    chmod 0755, so
    rm unsigned
    lib.install so => "libtailwind_oxide.so"
  end

  test do
    assert_predicate lib/"libtailwind_oxide.so", :exist?
  end
end
