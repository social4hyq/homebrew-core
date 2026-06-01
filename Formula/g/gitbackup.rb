class Gitbackup < Formula
  desc "Tool to backup your Bitbucket, GitHub and GitLab repositories"
  homepage "https://github.com/amitsaha/gitbackup"
  url "https://github.com/amitsaha/gitbackup/archive/refs/tags/v1.2.tar.gz"
  sha256 "13fe5e972897c9cd2548c569794088392c8e6a0296db10aa2c400cfeacd29e2a"
  license "MIT"
  head "https://github.com/amitsaha/gitbackup.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7ec61e3b3df02d6264b4b33b27ce31820fe8e2b895ab7df2b0157fbfe2e0b8ba"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args
  end

  test do
    assert_match "please specify the git service type", shell_output("#{bin}/gitbackup 2>&1", 1)
  end
end
