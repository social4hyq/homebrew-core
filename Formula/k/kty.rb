class Kty < Formula
  desc "Terminal for Kubernetes"
  homepage "https://kty.dev"
  url "https://github.com/grampelberg/kty/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "050c8b0df88f65e1a06863bea99495b77bf2045829825e7e130756f1828c6aa6"
  license "Apache-2.0"
  head "https://github.com/grampelberg/kty.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bbfcb359c1a5fcd6b24c5058160572fbf96e4c33a3c06c6f74b1b9d024805864"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    inreplace "Cargo.toml", "0.0.0-UNSTABLE", version.to_s
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kty -V")

    assert_match "failed to read an incluster environment variable",
                 shell_output("#{bin}/kty users check brew 2>&1", 1)
  end
end
