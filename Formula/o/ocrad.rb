class Ocrad < Formula
  desc "Optical character recognition (OCR) program"
  homepage "https://www.gnu.org/software/ocrad/"
  url "https://ftpmirror.gnu.org/gnu/ocrad/ocrad-0.29.tar.lz"
  mirror "https://ftp.gnu.org/gnu/ocrad/ocrad-0.29.tar.lz"
  sha256 "11200cc6b0b7ba16884a72dccb58ef694f7aa26cd2b2041e555580f064d2d9e9"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "100f33354fb0a7114633d3a60e127f160252a8db1198ef00b995d9b5a857dd79"
  end

  depends_on "libpng"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install", "CXXFLAGS=#{ENV.cxxflags}"
  end

  test do
    (testpath/"test.pbm").write <<~EOS
      P1
      # This is an example bitmap of the letter "J"
      6 10
      0 0 0 0 1 0
      0 0 0 0 1 0
      0 0 0 0 1 0
      0 0 0 0 1 0
      0 0 0 0 1 0
      0 0 0 0 1 0
      1 0 0 0 1 0
      0 1 1 1 0 0
      0 0 0 0 0 0
      0 0 0 0 0 0
    EOS
    assert_equal "J", `#{bin}/ocrad #{testpath}/test.pbm`.strip
  end
end
