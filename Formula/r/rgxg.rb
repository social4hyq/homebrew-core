class Rgxg < Formula
  desc "C library and command-line tool to generate (extended) regular expressions"
  homepage "https://rgxg.github.io"
  url "https://github.com/rgxg/rgxg/releases/download/v0.1.2/rgxg-0.1.2.tar.gz"
  sha256 "554741f95dcc320459875c248e2cc347b99f809d9555c957d763d3d844e917c6"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9560f3efd770eb7fb310a8049d0fdb48abf297e7f498fcb004ee828ad0f23aa4"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"rgxg", "range", "1", "10"
  end
end
