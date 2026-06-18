class Libre < Formula
  desc "Toolkit library for asynchronous network I/O with protocol stacks"
  homepage "https://github.com/baresip/re"
  url "https://github.com/baresip/re/archive/refs/tags/v4.9.0.tar.gz"
  sha256 "2094822477e4b68bf03089fe29b43b5160103ba846847004df25f9e3d65fabb6"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ecfb55b0139dbbedac6c692f08c184151e374119ae0f98d0c48f78d64936cbfc"
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
