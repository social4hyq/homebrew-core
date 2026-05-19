class Titlecase < Formula
  desc "Script to convert text to title case"
  homepage "http://plasmasturm.org/code/titlecase/"
  url "https://github.com/ap/titlecase/archive/refs/tags/v1.015.tar.gz"
  sha256 "908ef5c40d103200bcc9bd8a55171f20e14d09166aaa556dc91611567d695811"
  license "MIT"
  head "https://github.com/ap/titlecase.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "459f414ea0bac5199867449da989e44640f99383b4afb61c370f678f0b7ef4d8"
  end

  def install
    bin.install "titlecase"
  end

  test do
    (testpath/"test").write "homebrew"
    assert_equal "Homebrew\n", shell_output("#{bin}/titlecase test")
  end
end
