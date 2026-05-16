class Mapcidr < Formula
  desc "Subnet/CIDR operation utility"
  homepage "https://projectdiscovery.io"
  url "https://github.com/projectdiscovery/mapcidr/archive/refs/tags/v1.1.97.tar.gz"
  sha256 "d1253ab474de254cb77628d3274bf6fdcf087223f219dcf26186de83776bf717"
  license "MIT"
  head "https://github.com/projectdiscovery/mapcidr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1057acebdcaea9eb3d9ef723ab2724c092b20c3b08a122cbfe1af49223859889"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/mapcidr"
  end

  test do
    expected = "192.168.0.0/18\n192.168.64.0/18\n192.168.128.0/18\n192.168.192.0/18\n"
    output = shell_output("#{bin}/mapcidr -cidr 192.168.1.0/16 -sbh 16384 -silent")
    assert_equal expected, output
  end
end
