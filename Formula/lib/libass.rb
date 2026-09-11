class Libass < Formula
  desc "Subtitle renderer for the ASS/SSA subtitle format"
  homepage "https://github.com/libass/libass"
  url "https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz"
  sha256 "2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc"
  license "ISC"
  revision 1
  compatibility_version 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "372623e2f212c9edbb0a68371152b92cef4cb5398780ac4132f0bfb900ff4458"
  end

  head do
    url "https://github.com/libass/libass.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "freetype"
  depends_on "fribidi"
  depends_on "harfbuzz"
  depends_on "libunibreak"

  on_linux do
    depends_on "fontconfig"
  end

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    # libass uses coretext on macOS, fontconfig on Linux
    args = OS.mac? ? ["--disable-fontconfig"] : []

    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "ass/ass.h"
      int main() {
        ASS_Library *library;
        ASS_Renderer *renderer;
        library = ass_library_init();
        if (library) {
          renderer = ass_renderer_init(library);
          if (renderer) {
            ass_renderer_done(renderer);
            ass_library_done(library);
            return 0;
          }
          else {
            ass_library_done(library);
            return 1;
          }
        }
        else {
          return 1;
        }
      }
    CPP
    system ENV.cc, "test.cpp", "-I#{include}", "-L#{lib}", "-lass", "-o", "test"
    system "./test"
  end
end
