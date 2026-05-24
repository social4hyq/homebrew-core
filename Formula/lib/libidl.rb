class Libidl < Formula
  desc "Library for creating CORBA IDL files"
  homepage "https://download.gnome.org/sources/libIDL/0.8/"
  url "https://download.gnome.org/sources/libIDL/0.8/libIDL-0.8.14.tar.bz2"
  sha256 "c5d24d8c096546353fbc7cedf208392d5a02afe9d56ebcc1cccb258d7c4d2220"
  license "LGPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c2e32edf83d783d7f698a1976bc5527640248ab2cb2159639fa9ae5a3ba0fc7"
  end

  depends_on "gettext" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glib"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libIDL/IDL.h>
      int main(void) {
        return 0;
      }
    C

    pkg_config_flags = shell_output("pkg-config --cflags --libs libIDL-2.0").chomp.split
    system ENV.cc, "test.c", *pkg_config_flags, "-o", "test"
    system "./test"
  end
end
