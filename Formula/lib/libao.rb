class Libao < Formula
  desc "Cross-platform Audio Library"
  homepage "https://www.xiph.org/ao/"
  url "https://deb.debian.org/debian/pool/main/liba/libao/libao_1.2.2+20180113.orig.tar.gz"
  version "1.2.1"
  sha256 "cc9e68134e74f62a1feb6d07e4a0fb565351d80205d1e5d48d540b6abc4cf07d"
  license "GPL-2.0-or-later"
  compatibility_version 1
  head "https://gitlab.xiph.org/xiph/libao.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aaad20d17e57e7ed1eb3251040e9b5643e4651b019d3cb769a408ee041c31c27"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    ENV["AUTOMAKE_FLAGS"] = "--include-deps"
    system "./autogen.sh"
    system "./configure", "--enable-static", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <ao/ao.h>
      int main() {
        ao_initialize();
        return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-I#{include}", "-L#{lib}", "-lao", "-o", "test"
    system "./test"
  end
end
