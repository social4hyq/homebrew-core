class Libtins < Formula
  desc "C++ network packet sniffing and crafting library"
  homepage "https://libtins.github.io/"
  url "https://github.com/mfontanini/libtins/archive/refs/tags/v4.5.tar.gz"
  sha256 "6ff5fe1ada10daef8538743dccb9c9b3e19d05d028ffdc24838e62ff3fc55841"
  license "BSD-2-Clause"
  head "https://github.com/mfontanini/libtins.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21561c0d900cacef2cbc0588cdf3129d292376025d1e01870a8bddbc32ac264c"
  end

  depends_on "cmake" => :build
  depends_on "openssl@4"

  uses_from_macos "libpcap"

  def install
    args = %w[
      -DLIBTINS_BUILD_EXAMPLES=OFF
      -DLIBTINS_BUILD_TESTS=OFF
      -DLIBTINS_ENABLE_CXX11=ON
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <tins/tins.h>
      int main() {
        Tins::Sniffer sniffer("en0");
      }
    CPP
    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-ltins", "-o", "test"
  end
end
