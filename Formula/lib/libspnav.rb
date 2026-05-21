class Libspnav < Formula
  desc "Client library for connecting to 3Dconnexion's 3D input devices"
  homepage "https://spacenav.sourceforge.net/"
  url "https://github.com/FreeSpacenav/libspnav/releases/download/v1.2/libspnav-1.2.tar.gz"
  sha256 "093747e7e03b232e08ff77f1ad7f48552c06ac5236316a5012db4269951c39db"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "173995ac9916cab6275dfd2a2303824231fe581ac368291b88ebc12b0951eeb8"
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --disable-x11
    ]

    system "./configure", *args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <spnav.h>

      int main() {
        bool connected = spnav_open() != -1;
        if (connected) spnav_close();
        return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-I#{include}", "-L#{lib}", "-lspnav", "-lm", "-o", "test"
    system "./test"
  end
end
