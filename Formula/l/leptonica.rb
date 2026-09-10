class Leptonica < Formula
  desc "Image processing and image analysis library"
  homepage "http://www.leptonica.org/"
  url "https://github.com/DanBloomberg/leptonica/releases/download/1.87.0/leptonica-1.87.0.tar.gz"
  sha256 "c73363397f96eb1295602bf44d708a994ad42046c791bf03ea0505d829bdb6a7"
  license "BSD-2-Clause"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f5f76b43e1d710c6f3655fd080194fba19977995b2c75fa15c8a76a69eb4ca64"
  end

  depends_on "pkgconf" => :build
  depends_on "giflib"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openjpeg"
  depends_on "webp"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--with-libwebp", "--with-libopenjpeg", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <leptonica/allheaders.h>

      int main(int argc, char **argv) {
          fprintf(stdout, "%d.%d.%d", LIBLEPT_MAJOR_VERSION, LIBLEPT_MINOR_VERSION, LIBLEPT_PATCH_VERSION);
          return 0;
      }
    CPP

    flags = ["-I#{include}/leptonica"] + ENV.cflags.to_s.split
    system ENV.cxx, "test.cpp", *flags
    assert_equal version.to_s, shell_output("./a.out")
  end
end
