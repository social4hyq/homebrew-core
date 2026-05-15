class Zix < Formula
  desc "C99 portability and data structure library"
  homepage "https://gitlab.com/drobilla/zix"
  url "https://gitlab.com/drobilla/zix/-/archive/v0.8.0/zix-v0.8.0.tar.gz"
  sha256 "51d70d63e970214db84e32d55377d84090c02145f5768265ab140d117f2b8e24"
  license "ISC"
  head "https://gitlab.com/drobilla/zix.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "959756764cef8d42cf6a64edc2a12f03ff07323d7c4484736b9412026ab9591d"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "glib"

  def install
    args = %w[
      -Dbenchmarks=disabled
      -Dtests=disabled
    ]
    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "zix/attributes.h"
      #include "zix/string_view.h"

      #if defined(__GNUC__)
      #  pragma GCC diagnostic push
      #  pragma GCC diagnostic ignored "-Wunused-variable"
      #endif

      static void
      string_views(void)
      {
        const char* const string_pointer = "some string";

        // begin make-empty-string
        ZixStringView empty = zix_empty_string();
        // end make-empty-string

        // begin make-static-string
        static const ZixStringView hello = ZIX_STATIC_STRING("hello");
        // end make-static-string
        (void)hello;

        // begin measure-string
        ZixStringView view = zix_string(string_pointer);
        // end measure-string

        // begin make-string-view
        ZixStringView slice = zix_substring(string_pointer, 4);
        // end make-string-view
      }

      ZIX_CONST_FUNC
      int
      main(void)
      {
        string_views();
        return 0;
      }

      #if defined(__GNUC__)
      #  pragma GCC diagnostic pop
      #endif
    C
    system ENV.cc, "test.c", "-I#{include}/zix-0", "-o", "test"
    system "./test"
  end
end
