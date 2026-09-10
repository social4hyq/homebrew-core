class Libvncserver < Formula
  desc "VNC server and client libraries"
  homepage "https://libvnc.github.io"
  url "https://github.com/LibVNC/libvncserver/archive/refs/tags/LibVNCServer-0.9.15.tar.gz"
  sha256 "62352c7795e231dfce044beb96156065a05a05c974e5de9e023d688d8ff675d7"
  license "GPL-2.0-or-later"
  revision 2
  head "https://github.com/LibVNC/libvncserver.git", branch: "master"

  livecheck do
    url :stable
    regex(/^LibVNCServer[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9844d6b1ea9ca39eb4baa2f1b144ccc3a63f583572bb04c86a81d765cf16a0e"
  end

  depends_on "cmake" => :build
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "openssl@4"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      -DJPEG_INCLUDE_DIR=#{Formula["jpeg-turbo"].opt_include}
      -DJPEG_LIBRARY=#{Formula["jpeg-turbo"].opt_lib/shared_library("libjpeg")}
      -DOPENSSL_ROOT_DIR=#{Formula["openssl@4"].opt_prefix}
      -DWITH_EXAMPLES=OFF
      -DWITH_GCRYPT=OFF
      -DWITH_GNUTLS=OFF
      -DWITH_OPENSSL=ON
    ]
    # Workaround for CMake 4 compatibility
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "ctest", "--test-dir", "build", "--verbose"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"server.cpp").write <<~CPP
      #include <rfb/rfb.h>
      int main(int argc,char** argv) {
        rfbScreenInfoPtr server=rfbGetScreen(&argc,argv,400,300,8,3,4);
        server->frameBuffer=(char*)malloc(400*300*4);
        rfbInitServer(server);
        return(0);
      }
    CPP

    system ENV.cc, "server.cpp", "-I#{include}", "-L#{lib}",
                   "-lvncserver", "-o", "server"
    system "./server"
  end
end
