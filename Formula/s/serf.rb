class Serf < Formula
  desc "Service orchestration and management tool"
  homepage "https://github.com/hashicorp/serf"
  url "https://github.com/hashicorp/serf/archive/refs/tags/v0.10.4.tar.gz"
  sha256 "14b667203f34dd0a2cb54fcf863cd91799268f8b20230ad893fc36c23a1c7a00"
  license "MPL-2.0"
  head "https://github.com/hashicorp/serf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68b4f697ac856715809bc209963128429f8b3b05fd06190d4b9c844c86e0fcd5"
  end

  depends_on "go" => :build

  uses_from_macos "zip" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/hashicorp/serf/version.Version=#{version}
      -X github.com/hashicorp/serf/version.VersionPrerelease=
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/serf"
  end

  test do
    pid = spawn bin/"serf", "agent"
    sleep 1
    assert_match(/:7946.*alive$/, shell_output("#{bin}/serf members"))
  ensure
    system bin/"serf", "leave"
    Process.kill "SIGINT", pid
    Process.wait pid
  end
end
