class Md4c < Formula
  desc "C Markdown parser. Fast. SAX-like interface"
  homepage "https://github.com/mity/md4c"
  url "https://github.com/mity/md4c/archive/refs/tags/release-0.5.3.tar.gz"
  sha256 "353c346f376b87c954a13f3415ede2d51264cc61dc5abcd38ff1d2aa0d059b9e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1becbcb6a87b3d1042a5feee588e5dc8fc56dc7a9d8c7fd220675ad7bc7ec30"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # test md2html
    (testpath/"test_md.md").write <<~MARKDOWN
      # Title
      some text
    MARKDOWN
    system bin/"md2html", "./test_md.md"

    # test libmd4c
    (testpath/"test_program.c").write <<~C
      #include <stddef.h>
      #include <md4c.h>

      MD_CHAR* text = "# Title\\nsome text";

      int test_block(MD_BLOCKTYPE type, void* detail, void* data) { return 0; }
      int test_span(MD_SPANTYPE type, void* detail, void* data) { return 0; }
      int test_text(MD_TEXTTYPE type, const MD_CHAR* text, MD_SIZE size, void* userdata) { return 0; }
      int main() {
        MD_PARSER parser = {
          .enter_block = test_block,
          .leave_block = test_block,
          .enter_span = test_span,
          .leave_span = test_span,
          .text = test_text
        };
        int result = md_parse(text, sizeof(text), &parser, NULL);
        return result;
      }
    C
    system ENV.cc, "test_program.c", "-L#{lib}", "-lmd4c", "-o", "test_program"
    system "./test_program"
  end
end
