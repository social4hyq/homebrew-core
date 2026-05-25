class Cidr < Formula
  desc "CLI to perform various actions on CIDR ranges"
  homepage "https://github.com/bschaatsbergen/cidr"
  url "https://github.com/bschaatsbergen/cidr/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "caa803f91b634bfa955c4898abf3085b83c5c3cbcd56f81cc64f29510a99f707"
  license "MIT"
  head "https://github.com/bschaatsbergen/cidr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f3d0e5b933fb286048aa4bd197f5153f679712ddf47fa35534e77345301dd24"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    ldflags = %W[
      -s -w
      -X github.com/bschaatsbergen/cidr/cmd.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cidr --version")
    assert_equal "65536\n", shell_output("#{bin}/cidr count 10.0.0.0/16")
    assert_equal "1\n", shell_output("#{bin}/cidr count 10.0.0.0/32")
    assert_equal "false\n", shell_output("#{bin}/cidr overlaps 10.106.147.0/24 10.106.149.0/23")
  end
end
