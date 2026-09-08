class Bzip3 < Formula
  desc "Better and stronger spiritual successor to BZip2"
  homepage "https://github.com/kspalaiologos/bzip3"
  url "https://github.com/kspalaiologos/bzip3/releases/download/1.5.4/bzip3-1.5.4.tar.gz"
  sha256 "89a5e4bf29e4aae98b29bb1ef275addfa2d0806ba1ef60bf8a87263cdb21f581"
  license "LGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7465913c39d1a5049897caa79d29ca1a907767a9ea61aaf309907093f709f897"
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
