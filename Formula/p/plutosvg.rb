class Plutosvg < Formula
  desc "Tiny SVG rendering library in C"
  homepage "https://github.com/sammycage/plutosvg"
  url "https://github.com/sammycage/plutosvg/archive/refs/tags/v0.0.8.tar.gz"
  sha256 "49d5cfe772d3aa10cd4879f2f6e189f5083c08e4c8ea01bf3d5b87c97dfca7d2"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e8d99290fd1df9c78701fbe0422fccca0ec42591d7fd14cb4e36ec2bf482c5a7"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test
  depends_on "freetype"
  depends_on "plutovg"

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DPLUTOSVG_BUILD_EXAMPLES=OFF
      -DPLUTOSVG_ENABLE_FREETYPE=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <plutosvg.h>
      #include <stdio.h>

      int main(void) {
        plutosvg_document_t* document = plutosvg_document_load_from_file("test.svg", -1, -1);
        if(document == NULL) {
          printf("Unable to load: test.svg");
          return -1;
        }

        plutovg_surface_t* surface = plutosvg_document_render_to_surface(document, NULL, -1, -1, NULL, NULL, NULL);
        plutovg_surface_write_to_png(surface, "test.png");
        plutosvg_document_destroy(document);
        plutovg_surface_destroy(surface);
        return 0;
      }
    C

    cp test_fixtures("test.svg"), testpath
    system ENV.cc, "test.c", "-o", "test", *shell_output("pkgconf --cflags --libs plutosvg").chomp.split
    system "./test"
    assert_path_exists "test.png"
  end
end
