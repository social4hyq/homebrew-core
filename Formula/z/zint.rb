class Zint < Formula
  desc "Barcode encoding library supporting over 50 symbologies"
  homepage "https://www.zint.org.uk/"
  url "https://downloads.sourceforge.net/project/zint/zint/2.16.0/zint-2.16.0-src.tar.gz"
  sha256 "37e767afada2403bb9ae49b93a19eb0a9e944a0c278d9f23522746b3d08a3c4b"
  license "GPL-3.0-or-later"
  head "https://git.code.sf.net/p/zint/code.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{url=.*?/zint[._-]v?(\d+(?:\.\d+)+)(?:-src)?\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5f67589ea3a245663f5b523d1c3b5cecf55491fabbc53cfa333d81e9e432360f"
  end

  depends_on "cmake" => :build
  depends_on "libpng"

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <zint.h>
      #include <stdio.h>
      #include <stdlib.h>

      int main() {
        struct zint_symbol *my_symbol;

        my_symbol = ZBarcode_Create();
        my_symbol->symbology = BARCODE_CODE128;
        ZBarcode_Encode(my_symbol, (unsigned char *)"Test123", 7);
        ZBarcode_Print(my_symbol, 0);

        printf("Barcode successfully saved to out.png\\n");
        ZBarcode_Delete(my_symbol);

        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lzint"
    system "./test"
    assert_path_exists testpath/"out.png", "Failed to create barcode PNG"

    system bin/"zint", "-o", "test-zing.png", "-d", "This Text"
    assert_path_exists testpath/"test-zing.png", "Failed to create barcode PNG"

    assert_match version.to_s, shell_output("#{bin}/zint --version")
  end
end
