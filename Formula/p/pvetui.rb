class Pvetui < Formula
  desc "Terminal UI for Proxmox VE"
  homepage "https://pvetui.org"
  url "https://github.com/devnullvoid/pvetui/archive/refs/tags/v1.4.3.tar.gz"
  sha256 "3d87fcf9ffca7d25daac2c1ef7f6275633d2793925537f6893f350bf1b4f463a"
  license "MIT"
  head "https://github.com/devnullvoid/pvetui.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82c56bf4b3cfcd585d874d2c9225355f32da603209cb4e0eb334986dd7828285"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/devnullvoid/pvetui/internal/version.version=#{version}
      -X github.com/devnullvoid/pvetui/internal/version.commit=#{tap.user}
      -X github.com/devnullvoid/pvetui/internal/version.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/pvetui"
  end

  test do
    assert_match "It looks like this is your first time running pvetui.", pipe_output(bin/"pvetui", "n")
    assert_match version.to_s, shell_output("#{bin}/pvetui --version")
  end
end
