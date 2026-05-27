class Omekasy < Formula
  desc "Converts alphanumeric input to various Unicode styles"
  homepage "https://github.com/ikanago/omekasy"
  url "https://github.com/ikanago/omekasy/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "0def519ad64396aa12b341dee459049fb54a3cfae265ae739da5e65ca1d7e377"
  license "MIT"
  head "https://github.com/ikanago/omekasy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf5272edd2049ac582645e6d5612387ba283d6d3f6ede4c84a1898c361aeb213"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/omekasy --version")
    output = shell_output("#{bin}/omekasy -f monospace Hello")
    assert_match "𝙷𝚎𝚕𝚕𝚘", output
  end
end
