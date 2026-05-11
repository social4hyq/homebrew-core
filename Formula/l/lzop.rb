class Lzop < Formula
  desc "File compressor"
  homepage "https://www.lzop.org/"
  url "https://www.lzop.org/download/lzop-1.04.tar.gz"
  sha256 "7e72b62a8a60aff5200a047eea0773a8fb205caf7acbe1774d95147f305a2f41"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.lzop.org/download/"
    regex(/href=.*?lzop[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e393847cc87b79c014542949f479a480e8c8207370540828f36498033304253c"
  end

  depends_on "lzo"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    path = testpath/"test"
    text = "This is Homebrew"
    path.write text

    system bin/"lzop", "test"
    assert_path_exists testpath/"test.lzo"
    rm path

    system bin/"lzop", "-d", "test.lzo"
    assert_equal text, path.read
  end
end
