class Havn < Formula
  desc "Fast configurable port scanner with reasonable defaults"
  homepage "https://github.com/mrjackwills/havn"
  url "https://github.com/mrjackwills/havn/archive/refs/tags/v0.3.8.tar.gz"
  sha256 "9490f81539664dd7e9749c63866fb2892a7d4a55cc83002f17fbdb07e08b2c36"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6acd50b2e44f2edd81d766c5e0ddab059fd574f7043b6d900e138779c9f03add"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output("#{bin}/havn example.com -p 443 -r 6")
    assert_match "1 open\e[0m, \e[31m0 closed", output

    assert_match version.to_s, shell_output("#{bin}/havn --version")
  end
end
