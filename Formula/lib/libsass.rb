class Libsass < Formula
  desc "C implementation of a Sass compiler"
  homepage "https://github.com/sass/libsass"
  url "https://github.com/sass/libsass.git",
      tag:      "3.6.6",
      revision: "7037f03fabeb2b18b5efa84403f5a6d7a990f460"
  license "MIT"
  compatibility_version 1
  head "https://github.com/sass/libsass.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a0b63f82de2260afabcff7847f7a89a28257e212e70a11e6567a2bb70e0d3826"
  end

  deprecate! date: "2026-04-02", because: :repo_archived
  disable! date: "2027-04-02", because: :repo_archived

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    ENV.cxx11
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    # This will need to be updated when devel = stable due to API changes.
    (testpath/"test.c").write <<~C
      #include <sass/context.h>
      #include <string.h>

      int main()
      {
        const char* source_string = "a { color:blue; &:hover { color:red; } }";
        struct Sass_Data_Context* data_ctx = sass_make_data_context(strdup(source_string));
        struct Sass_Options* options = sass_data_context_get_options(data_ctx);
        sass_option_set_precision(options, 1);
        sass_option_set_source_comments(options, false);
        sass_data_context_set_options(data_ctx, options);
        sass_compile_data_context(data_ctx);
        struct Sass_Context* ctx = sass_data_context_get_context(data_ctx);
        int err = sass_context_get_error_status(ctx);
        if(err != 0) {
          return 1;
        } else {
          return strcmp(sass_context_get_output_string(ctx), "a {\\n  color: blue; }\\n  a:hover {\\n    color: red; }\\n") != 0;
        }
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-L#{lib}", "-lsass"
    system "./test"
  end
end
