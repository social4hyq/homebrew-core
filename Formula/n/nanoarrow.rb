class Nanoarrow < Formula
  desc "Helpers for Arrow C Data & Arrow C Stream interfaces"
  homepage "https://arrow.apache.org/nanoarrow"
  url "https://github.com/apache/arrow-nanoarrow/archive/refs/tags/apache-arrow-nanoarrow-0.8.0.tar.gz"
  sha256 "1c5136edf5c1e9cd8c47c4e31dfe07d0e09c25f27be20c8d6e78a0f4a4ed3fae"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "480aef8eef98b6646b211ada1fbc6efd3078dd821d92427b0e370bda15b81521"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nanoarrow/nanoarrow.h>

      int main() {
        ArrowBufferAllocatorDefault();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lnanoarrow_shared", "-o", "test"
    system "./test"
  end
end
