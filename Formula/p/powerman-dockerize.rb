class PowermanDockerize < Formula
  desc "Utility to simplify running applications in docker containers"
  homepage "https://github.com/powerman/dockerize"
  url "https://github.com/powerman/dockerize.git",
      tag:      "v0.25.2",
      revision: "311635aeeeac3869b2550879c856510698d05969"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34f4b950d9d33799aa6bceec36b70fb67d1635c317c3740169f588703e52a037"
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
