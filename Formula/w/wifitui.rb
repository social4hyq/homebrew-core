class Wifitui < Formula
  desc "Fast featureful friendly wifi terminal UI"
  homepage "https://github.com/shazow/wifitui"
  url "https://github.com/shazow/wifitui/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "bdcf779c341916e692f3dad26b33121a2acab6e35d68b95e5415cf1e249b5e2e"
  license "MIT"
  head "https://github.com/shazow/wifitui.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ff4766b436cd4dd46c2a6efc509b3f49cf93791fca63471143e1629b8eff1f4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wifitui --version")

    expected = if OS.mac?
      "no Wi-Fi interface found"
    else
      "error: dial unix /var/run/dbus/system_bus_socket: connect: no such file or directory"
    end

    assert_match expected, shell_output("#{bin}/wifitui show nonexistent_network_id 2>&1", 1)
  end
end
