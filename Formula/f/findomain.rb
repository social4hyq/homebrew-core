class Findomain < Formula
  desc "Cross-platform subdomain enumerator"
  homepage "https://github.com/Findomain/Findomain"
  url "https://github.com/Findomain/Findomain/archive/refs/tags/10.0.1.tar.gz"
  sha256 "2562943c29a9b3ce1b76685d9e7de1ad5109f80a35c6941e7853b31fb92641fa"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2eb35bde8f15d9d18900cecfb97a1aa4ed39dfe8b1d983a9129a00c5ee5fb302"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "Good luck Hax0r", shell_output("#{bin}/findomain -t brew.sh")
  end
end
