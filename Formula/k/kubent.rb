class Kubent < Formula
  desc "Easily check your clusters for use of deprecated APIs"
  homepage "https://github.com/doitintl/kube-no-trouble"
  url "https://github.com/doitintl/kube-no-trouble.git",
      tag:      "0.7.3",
      revision: "57480c07b3f91238f12a35d0ec88d9368aae99aa"
  license "MIT"
  head "https://github.com/doitintl/kube-no-trouble.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5a5e650d8fcb1319575d6944665e85147429a6bea16a8c5c13058ed9c6f207f0"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.gitSha=#{Utils.git_head}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/kubent"
  end

  test do
    assert_match "no configuration has been provided", shell_output("#{bin}/kubent 2>&1")
    assert_match version.to_s, shell_output("#{bin}/kubent --version 2>&1")
  end
end
