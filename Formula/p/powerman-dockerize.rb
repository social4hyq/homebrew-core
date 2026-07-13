class PowermanDockerize < Formula
  desc "Utility to simplify running applications in docker containers"
  homepage "https://github.com/powerman/dockerize"
  url "https://github.com/powerman/dockerize.git",
      tag:      "v0.25.1",
      revision: "5c3e5e906d9ef8f8b4b7510852f6d08bd410f418"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88764f0bbde9eb9c7da4eb4135617eead7fdd4241571b98f2601bec5765e2ca4"
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
