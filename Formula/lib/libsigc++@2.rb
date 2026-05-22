class LibsigcxxAT2 < Formula
  desc "Callback framework for C++"
  homepage "https://libsigcplusplus.github.io/libsigcplusplus/"
  url "https://github.com/libsigcplusplus/libsigcplusplus/releases/download/2.12.2/libsigc++-2.12.2.tar.xz"
  sha256 "7d4cdf1e4332ebfee8085ad960075045e7763cb291b3ccf4744d7cbf08a22b75"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(2\.([0-8]\d*?)?[02468](?:\.\d+)*?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5347eb0c4d2d614efe156e8201d86e5ee83507745bdfb7dce9c6ab750e44b911"
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
      #include <sigc++/sigc++.h>

      void somefunction(int arg) {}

      int main(int argc, char *argv[])
      {
         sigc::slot<void, int> sl = sigc::ptr_fun(&somefunction);
         return 0;
      }
    CPP
    system ENV.cxx, "-std=c++11", "test.cpp",
                   "-L#{lib}", "-lsigc-2.0", "-I#{include}/sigc++-2.0", "-I#{lib}/sigc++-2.0/include", "-o", "test"
    system "./test"
  end
end
