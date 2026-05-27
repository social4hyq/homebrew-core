class Nuttcp < Formula
  desc "Network performance measurement tool"
  homepage "https://www.nuttcp.net/nuttcp/"
  url "https://www.nuttcp.net/nuttcp/nuttcp-8.2.2.tar.bz2"
  sha256 "7ead7a89e7aaa059d20e34042c58a198c2981cad729550d1388ddfc9036d3983"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    regex(/href=.*?nuttcp[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d4f6414ff84e6731c1fe4bf7ec4e44c3c765883e31f6a360e45bec3f8c0012d"
  end

  def install
    system "make", "APP=nuttcp",
           "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}"
    bin.install "nuttcp"
    man8.install "nuttcp.cat" => "nuttcp.8"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nuttcp -V")
  end
end
