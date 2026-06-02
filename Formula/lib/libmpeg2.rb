class Libmpeg2 < Formula
  desc "Library to decode mpeg-2 and mpeg-1 video streams"
  homepage "https://libmpeg2.sourceforge.io/"
  url "https://download.videolan.org/contrib/libmpeg2/libmpeg2-0.5.1.tar.gz"
  mirror "https://libmpeg2.sourceforge.io/files/libmpeg2-0.5.1.tar.gz"
  sha256 "dee22e893cb5fc2b2b6ebd60b88478ab8556cb3b93f9a0d7ce8f3b61851871d4"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://libmpeg2.sourceforge.io/downloads.html"
    regex(/href=.*?libmpeg2[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e5666f166c6f9ad4b4432f143b0f5cdce5c4cbab19aa61e68b772e70b507593"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  on_linux do
    depends_on "libx11"
    depends_on "libxext"
  end

  def install
    # Otherwise compilation fails in clang with `duplicate symbol ___sputc`
    ENV.append "CFLAGS", "-std=gnu89"

    system "autoreconf", "--force", "--install", "--verbose"
    # Build without old SDL 1.2 similar to Debian and Arch Linux
    system "./configure", "--disable-sdl", *std_configure_args
    system "make", "install"
    pkgshare.install "doc/sample1.c"
  end

  test do
    system ENV.cc, "-I#{include}/mpeg2dec", pkgshare/"sample1.c", "-L#{lib}", "-lmpeg2"
  end
end
