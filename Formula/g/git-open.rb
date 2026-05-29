class GitOpen < Formula
  desc "Open GitHub webpages from a terminal"
  homepage "https://github.com/jeffreyiacono/git-open"
  url "https://github.com/jeffreyiacono/git-open/archive/refs/tags/v1.3.tar.gz"
  sha256 "a1217e9b0a76382a96afd33ecbacad723528ec1116381c22a17cc7458de23701"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a1c21cc5646d75d8698af9e610fa2e582efabbe8e46e9b768b2f3746517e0ea"
  end

  def install
    bin.install "git-open.sh" => "git-open"
  end

  test do
    system bin/"git-open", "-v"
  end
end
