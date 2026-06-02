class Tcpsplit < Formula
  desc "Break a packet trace into some number of sub-traces"
  homepage "https://www.icir.org/mallman/software/tcpsplit/"
  url "https://www.icir.org/mallman/software/tcpsplit/tcpsplit-0.3.tar.gz"
  sha256 "9ba0a12d294fa4ccc8cad8d9662126f01b436ced48642c3fb2520121943f5cf5"
  # The license is similar to X11 but with a different phrasing to the no advertising clause
  license :cannot_represent

  livecheck do
    url :homepage
    regex(/href=.*?tcpsplit[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "28dbb117c6e0d0c9200fe5fe2eb75e2fe9c1f36ff6fec5fba68e12364c6fa7b4"
  end

  uses_from_macos "libpcap"

  def install
    system "make"
    bin.install "tcpsplit"
  end

  test do
    system bin/"tcpsplit", "--version"
  end
end
