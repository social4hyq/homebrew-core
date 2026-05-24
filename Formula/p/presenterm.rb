class Presenterm < Formula
  desc "Terminal slideshow tool"
  homepage "https://github.com/mfontanini/presenterm"
  url "https://github.com/mfontanini/presenterm/archive/refs/tags/v0.16.1.tar.gz"
  sha256 "221258deae7204c65a55d3666aaea5fa157312b4196a59abc60ba4d363787c10"
  license "BSD-2-Clause"
  head "https://github.com/mfontanini/presenterm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7901194b2aaebac5c72c0f2bd4bc6d3ba7e5fc18dcb7bf4421566189c07fdf5"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # presenterm is a TUI application
    assert_match version.to_s, shell_output("#{bin}/presenterm --version")
  end
end
