class Iamy < Formula
  desc "AWS IAM import and export tool"
  homepage "https://github.com/99designs/iamy"
  url "https://github.com/99designs/iamy/archive/refs/tags/v2.4.0.tar.gz"
  sha256 "13bd9e66afbeb30d386aa132a4af5d2e9a231d2aadf54fe8e5dc325583379359"
  license "MIT"
  revision 1
  head "https://github.com/99designs/iamy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c80195739f77b0322319a8b5cfcbdeac0dcdc2f4447f480363bb4f00816f1d7c"
  end

  depends_on "go" => :build
  depends_on "awscli"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=v#{version}")
  end

  test do
    ENV.delete "AWS_ACCESS_KEY"
    ENV.delete "AWS_SECRET_KEY"
    output = shell_output("#{bin}/iamy pull 2>&1", 1)
    assert_match "Can't determine the AWS account", output
  end
end
