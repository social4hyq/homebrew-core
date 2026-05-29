class Toml2json < Formula
  desc "Convert TOML to JSON"
  homepage "https://github.com/woodruffw/toml2json"
  url "https://github.com/woodruffw/toml2json/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "70c9bf872f22d22691d41eeb06442a0fddf4b341ddebfadf8734d1e68e0174ce"
  license "MIT"
  head "https://github.com/woodruffw/toml2json.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab1762bbb23ed4b4728e8dedbd4b550d95e4aca7df89cd6133f14ecfc6c91ad2"
  end

  depends_on "rust" => :build

  conflicts_with "remarshal", because: "both install `toml2json` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    out = pipe_output(bin/"toml2json", 'wow = "amazing"')
    json = JSON.parse(out)
    assert_equal "amazing", json.fetch("wow")
  end
end
