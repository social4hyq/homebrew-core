class Has < Formula
  desc "Checks presence of various command-line tools and their versions on the path"
  homepage "https://github.com/kdabir/has"
  url "https://github.com/kdabir/has/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "99b4b82d8b935521bd1b44bf7a6af3421f4c850a28b8edfee39e6ee75af4d78f"
  license "MIT"
  head "https://github.com/kdabir/has.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dc039a51f4ff6d18e544f1ada03f54827d8b86280b0da311cc19b86812c88a57"
  end

  def install
    bin.install "has"
  end

  test do
    assert_match "git", shell_output("#{bin}/has git")
    assert_match version.to_s, shell_output("#{bin}/has --version")
  end
end
