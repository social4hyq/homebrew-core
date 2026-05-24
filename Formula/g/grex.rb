class Grex < Formula
  desc "Command-line tool for generating regular expressions"
  homepage "https://github.com/pemistahl/grex"
  url "https://github.com/pemistahl/grex/archive/refs/tags/v1.4.6.tar.gz"
  sha256 "2ab9cb4c3d921711f23ea33a9e60dc11e9eaab450b16d1f2247bea2276822433"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "801ee3e10716ced777eb15e0f0699d05930b9d1f19c4e7556a332cc02c7e7746"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output("#{bin}/grex a b c")
    assert_match "^[a-c]$\n", output
  end
end
