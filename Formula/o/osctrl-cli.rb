class OsctrlCli < Formula
  desc "Fast and efficient osquery management"
  homepage "https://osctrl.net"
  url "https://github.com/jmpsec/osctrl/archive/refs/tags/v0.5.9.tar.gz"
  sha256 "2de1f3ba46cd9a82c0a40c9be7ad3cabccdda9fb16bd2d70c6ab113d21b145d8"
  license "MIT"
  head "https://github.com/jmpsec/osctrl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "132e75a624d8621c221a5ba0beb638a1826ee4b7234fa8805c65e2734e860c26"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/cli"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/osctrl-cli --version")

    output = shell_output("#{bin}/osctrl-cli check-db 2>&1", 1)
    assert_match "failed to create backend", output
  end
end
