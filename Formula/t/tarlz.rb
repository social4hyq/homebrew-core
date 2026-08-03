class Tarlz < Formula
  desc "Data compressor"
  homepage "https://www.nongnu.org/lzip/tarlz.html"
  url "https://download.savannah.gnu.org/releases/lzip/tarlz/tarlz-0.30.tar.lz"
  mirror "https://download-mirror.savannah.gnu.org/releases/lzip/tarlz/tarlz-0.30.tar.lz"
  sha256 "c6339319413f37fc4b155b1ba8a58640a7fee36498b095d3b6d3c13d9c7f286c"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/lzip/tarlz/"
    regex(/href=.*?tarlz[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e4d96ef81e9448ca9fcc6e17648b54c0a0d367411ea0722a13afc66e49c93397"
  end

  depends_on "lzlib"

  def install
    system "./configure", *std_configure_args
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    spath = testpath/"source"
    dpath = testpath/"destination"
    stestfilepath = spath/"test.txt"
    dtestfilepath = dpath/"source/test.txt"
    lzipfilepath = testpath/"test.tar.lz"
    stestfilepath.write "TEST CONTENT"

    mkdir_p spath
    mkdir_p dpath

    system bin/"tarlz", "-C", testpath, "-cf", lzipfilepath, "source"
    assert_path_exists lzipfilepath

    system bin/"tarlz", "-C", dpath, "-xf", lzipfilepath
    assert_equal "TEST CONTENT", dtestfilepath.read
  end
end
