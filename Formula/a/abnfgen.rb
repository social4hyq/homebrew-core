class Abnfgen < Formula
  desc "Quickly generate random documents that match an ABFN grammar"
  homepage "https://www.quut.com/abnfgen/"
  url "https://www.quut.com/abnfgen/abnfgen-0.21.tar.gz"
  sha256 "5bf784e6010b4b67e38fa18632b7e2b221c1a7a43a0907be0379a4909f5e536e"
  license :cannot_represent

  livecheck do
    url :homepage
    regex(%r{href=.*?/abnfgen[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b63b78daa675b2899dec26caef75825b6d1191341f0307bad842c8cddb63a71"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"grammar").write 'ring = 1*12("ding" SP) "dong" CRLF'
    system bin/"abnfgen", (testpath/"grammar")
  end
end
