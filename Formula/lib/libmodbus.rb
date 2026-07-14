class Libmodbus < Formula
  desc "Portable modbus library"
  homepage "https://libmodbus.org/"
  url "https://github.com/stephane/libmodbus/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "0c61007b2815daf452618f8b877d15cdcd376b71ad5dbd06b330d70f53b2ccaa"
  license "LGPL-2.1-or-later"
  head "https://github.com/stephane/libmodbus.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1130a80aa446e8dc5c714ab4d49da8c8705cefe03760719d1d1570e82496f0d1"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  # Fix build on OHOS (musl): <sys/ioctl.h> does not transitively include
  # <asm/ioctls.h> like glibc does, so TCGETS2/TCSETS2 are not visible.
  # Explicitly include <asm/ioctls.h> when using termios2.
  patch do
    file "Patches/libmodbus/0001-configure-ac-add-asm-ioctls-h-check.patch"
  end

  patch do
    file "Patches/libmodbus/0002-modbus-rtu-include-asm-ioctls-h-for-TCGETS2.patch"
  end

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"hellomodbus.c").write <<~C
      #include <modbus.h>
      #include <stdio.h>
      int main() {
        modbus_t *mb;
        uint16_t tab_reg[32];

        mb = 0;
        mb = modbus_new_tcp("127.0.0.1", 1502);
        modbus_connect(mb);

        /* Read 5 registers from the address 0 */
        modbus_read_registers(mb, 0, 5, tab_reg);

        void *p = mb;
        modbus_close(mb);
        modbus_free(mb);
        mb = 0;
        return (p == 0);
      }
    C
    system ENV.cc, "hellomodbus.c", "-o", "foo", "-L#{lib}", "-lmodbus",
      "-I#{include}/libmodbus", "-I#{include}/modbus"
    system "./foo"
  end
end
