class Bzip3 < Formula
  desc "Better and stronger spiritual successor to BZip2"
  homepage "https://github.com/kspalaiologos/bzip3"
  url "https://github.com/kspalaiologos/bzip3/releases/download/1.5.3/bzip3-1.5.3.tar.gz"
  sha256 "c48823353084df2a5a0dba44fd5295abd078e40b49f09700d08af4d9b1e31d67"
  license "LGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9ec9802524e823a637986ed817afe78b8cbf5e5ecf450f8854a62b33740721c"
  end

  def install
    system "./configure", "--disable-silent-rules", "--disable-arch-native", *std_configure_args
    system "make", "install"
  end

  test do
    testfilepath = testpath + "sample_in.txt"
    zipfilepath = testpath + "sample_in.txt.bz3"

    testfilepath.write "TEST CONTENT"

    system bin/"bzip3", testfilepath
    system bin/"bunzip3", "-f", zipfilepath

    assert_equal "TEST CONTENT", testfilepath.read
  end
end
