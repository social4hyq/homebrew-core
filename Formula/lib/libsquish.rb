class Libsquish < Formula
  desc "Library for compressing images with the DXT standard"
  homepage "https://sourceforge.net/projects/libsquish/"
  url "https://downloads.sourceforge.net/project/libsquish/libsquish-1.15.tgz"
  sha256 "628796eeba608866183a61d080d46967c9dda6723bc0a3ec52324c85d2147269"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69c3a7f6457f6ea6f36f2aec130d4d6c3eb1cb9a5ce85175ccc0355cf5c80132"
  end

  depends_on "cmake" => :build

  def install
    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    args << "-DBUILD_SQUISH_WITH_SSE2=OFF" if Hardware::CPU.arm?
    # Static and shared libraries have to be built using separate calls to cmake.
    system "cmake", "-S", ".", "-B", "build_static", *std_cmake_args, *args
    system "cmake", "--build", "build_static"
    lib.install "build_static/libsquish.a"

    args << "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "-S", ".", "-B", "build_shared", *std_cmake_args, *args
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <stdio.h>
      #include <squish.h>
      int main(void) {
        printf("%d", GetStorageRequirements(640, 480, squish::kDxt1));
        return 0;
      }
    CPP
    system ENV.cxx, "-o", "test", "test.cc", "-L#{lib}", "-lsquish"
    assert_equal "153600", shell_output("./test")
  end
end
