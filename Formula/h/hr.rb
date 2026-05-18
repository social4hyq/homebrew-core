class Hr < Formula
  desc "<hr />, for your terminal window"
  homepage "https://github.com/LuRsT/hr"
  url "https://github.com/LuRsT/hr/archive/refs/tags/1.5.tar.gz"
  sha256 "d4bb6e8495a8adaf7a70935172695d06943b4b10efcbfe4f8fcf6d5fe97ca251"
  license "MIT"
  head "https://github.com/LuRsT/hr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4372f508ec2200b4adf56d526d1a1086c019ddb28c5a413d0e58801f2c223917"
  end

  def install
    bin.install "hr"
    man1.install "hr.1"
  end

  test do
    system bin/"hr", "-#-"
  end
end
