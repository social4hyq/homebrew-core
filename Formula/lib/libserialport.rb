class Libserialport < Formula
  desc "Cross-platform serial port C library"
  homepage "https://sigrok.org/wiki/Libserialport"
  url "https://sigrok.org/download/source/libserialport/libserialport-0.1.2.tar.gz"
  sha256 "5deb92b5ca72c0347b07b786848350deca2dcfd975ce613b8e0e1d947a4b4ca9"
  license "LGPL-3.0-or-later"

  livecheck do
    url "https://sigrok.org/wiki/Downloads"
    regex(/href=.*?libserialport[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ee694cb1f4d039150ee98edb91f48b42e06cf360af1ee3118edc6c2d6773de9a"
  end

  head do
    url "git://sigrok.org/libserialport", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libserialport.h>
      int main() {
       struct sp_port *list_ptr = NULL;
       sp_get_port_by_name("some port", &list_ptr);
       return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lserialport",
                   "-o", "test"
    system "./test"
  end
end
