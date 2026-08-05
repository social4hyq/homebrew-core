class Nanoarrow < Formula
  desc "Helpers for Arrow C Data & Arrow C Stream interfaces"
  homepage "https://arrow.apache.org/nanoarrow"
  url "https://github.com/apache/arrow-nanoarrow/archive/refs/tags/apache-arrow-nanoarrow-0.9.0.tar.gz"
  sha256 "22c3edeaa5cb384c6da091f32a4e1c937779f2d62f84d646028de658b03d4385"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db4d5b7004da3674c21f4f9b486f1fbc709eaff91acbc79f0f874a3f054ee571"
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
