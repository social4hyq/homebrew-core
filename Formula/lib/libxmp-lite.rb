class LibxmpLite < Formula
  desc "Lite libxmp"
  homepage "https://xmp.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/xmp/libxmp/4.7.0/libxmp-lite-4.7.0.tar.gz"
  sha256 "69967a7802d2d2f938347f6f9cd95232bf45a4623cbfcc196e37cdaefadc3974"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0cc11b9ffe6fba7c6eee09325bf3706afef3a5f5d2a75ecf050b29994d42612b"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <libxmp-lite/xmp.h>

      int main(int argc, char* argv[]){
        printf("libxmp-lite %s/%c%u\\n", XMP_VERSION, *xmp_version, xmp_vercode);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lxmp-lite", "-o", "test"
    system "./test"
  end
end
