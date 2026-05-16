class Smu < Formula
  desc "Simple markup with markdown-like syntax"
  homepage "https://github.com/Gottox/smu"
  url "https://github.com/Gottox/smu/archive/refs/tags/v1.5.tar.gz"
  sha256 "f3bb18f958962679a7fb48d7f8dcab8b59154d66f23c9aba02e78103106093a4"
  license "MIT"
  head "https://github.com/Gottox/smu.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0811a99641cb2258cfae0743cba96283b02ac8111cb0c112f681ba6e2a9ece4"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.md").write "[Homebrew](https://brew.sh)"
    assert_equal "<p><a href=\"https://brew.sh\">Homebrew</a></p>\n", shell_output("#{bin}/smu test.md")
  end
end
