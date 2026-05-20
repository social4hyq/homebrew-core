class PowermanDockerize < Formula
  desc "Utility to simplify running applications in docker containers"
  homepage "https://github.com/powerman/dockerize"
  url "https://github.com/powerman/dockerize.git",
      tag:      "v0.24.3",
      revision: "a21f69ff60cdf1b2d54dadb7d04f28c8b6723c19"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "190b82a144284ce2f93797dd38b1cadd1df3e5442bdfc868e80b236f16dd8595"
  end

  depends_on "go" => :build
  conflicts_with "dockerize", because: "powerman-dockerize and dockerize install conflicting executables"

  def install
    system "go", "build", *std_go_args(output: bin/"dockerize", ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dockerize --version")
    system bin/"dockerize", "-wait", "https://www.google.com/", "-wait-retry-interval=1s", "-timeout", "5s"
  end
end
