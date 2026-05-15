class Rmate < Formula
  desc "Edit files from an SSH session in TextMate"
  homepage "https://github.com/textmate/rmate"
  url "https://github.com/textmate/rmate/archive/refs/tags/v1.5.8.tar.gz"
  sha256 "40be07ae251bfa47b408eb56395dd2385d8e9ea220a19efd5145593cd8cbd89c"
  license "MIT"
  head "https://github.com/textmate/rmate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f62661e8395982c4338e0dec953abc57774d214ea7136aab8b1ac8e17aea620"
  end

  uses_from_macos "ruby"

  def install
    bin.install "bin/rmate"
  end

  test do
    system bin/"rmate", "--version"
  end
end
