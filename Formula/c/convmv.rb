class Convmv < Formula
  desc "Filename encoding conversion tool"
  homepage "https://www.j3e.de/linux/convmv/"
  url "https://www.j3e.de/linux/convmv/convmv-2.06.tar.gz"
  sha256 "a37192e266742e7fe33ec19a3be49aea7fd4d066887863a6e193fa345bf2e592"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?convmv[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6f6f57c366f2c84c26a655bc305e03adad89e403c2403cf605dac267927cb4d"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"convmv", "--list"
  end
end
