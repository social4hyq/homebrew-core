class Snzip < Formula
  desc "Compression/decompression tool based on snappy"
  homepage "https://github.com/kubo/snzip"
  url "https://github.com/kubo/snzip/releases/download/v1.0.5/snzip-1.0.5.tar.gz"
  sha256 "fbb6b816619628f385b62f44a00a1603be157fba6ed2d30de490b0c5e645bff8"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c8ad88543f8907cbcc4915dd5b3586954b81acfd460fac8c1106f06986e3dee9"
  end

  depends_on "snappy"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.out").write "test"
    system bin/"snzip", "test.out"
    system bin/"snzip", "-d", "test.out.sz"
  end
end
