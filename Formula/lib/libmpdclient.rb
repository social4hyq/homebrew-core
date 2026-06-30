class Libmpdclient < Formula
  desc "Library for MPD in the C, C++, and Objective-C languages"
  homepage "https://www.musicpd.org/libs/libmpdclient/"
  url "https://www.musicpd.org/download/libmpdclient/2/libmpdclient-2.26.tar.xz"
  sha256 "35785c6d6318ade47e2c27b00fc6938f5e09d04714080fea3f5e5c522ba3e036"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/MusicPlayerDaemon/libmpdclient.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?libmpdclient[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a487cf8ee21263c2ce47941dbb8b55de7f44f1825391249844e87bd3c525e460"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <mpd/client.h>
      int main() {
        mpd_connection_new(NULL, 0, 30000);
        return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-L#{lib}", "-lmpdclient", "-o", "test"
    system "./test"
  end
end
