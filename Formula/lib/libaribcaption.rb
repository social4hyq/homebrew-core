class Libaribcaption < Formula
  desc "Portable ARIB STD-B24 Caption Decoder/Renderer"
  homepage "https://github.com/xqq/libaribcaption"
  url "https://github.com/xqq/libaribcaption/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "649b50bde99272b97c66af2a8400163e2f84eae072d252daa26baaaf0866a1c2"
  license "MIT"
  head "https://github.com/xqq/libaribcaption.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f4fc3af4cea9cb7235804853db7b55485096065c9d2ae935163f9743dccd96e3"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => [:build, :test]

  on_linux do
    depends_on "fontconfig"
    depends_on "freetype"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", "-DARIBCC_SHARED_LIBRARY=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <aribcaption/decoder.h>

      int main(int argc, char *argv[]) {
        aribcc_context_t* ctx = aribcc_context_alloc();
        if (!ctx)
          return 1;
        aribcc_context_free(ctx);
        return 0;
      }
    C
    flags = shell_output("pkgconf --cflags --libs libaribcaption").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
