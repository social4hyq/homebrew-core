class Libre < Formula
  desc "Toolkit library for asynchronous network I/O with protocol stacks"
  homepage "https://github.com/baresip/re"
  url "https://github.com/baresip/re/archive/refs/tags/v4.8.1.tar.gz"
  sha256 "c71748a7d783c21f3031788a9e0af6add19d67a6aaf7712e723af27ebf131199"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1ace301a02389fccea6c3455989f09bc7921a0451526a55a93f1938bca06017"
  end

  depends_on "cmake" => :build
  depends_on "openssl@4"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdint.h>
      #include <re/re.h>
      int main() {
        return libre_init();
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-I#{include}/re", "-L#{lib}", "-lre"
    system "./test"
  end
end
