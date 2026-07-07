class Girara < Formula
  desc "Common components for zathura"
  homepage "https://pwmt.org/projects/girara/"
  url "https://pwmt.org/projects/girara/download/girara-2026.07.07.tar.xz"
  sha256 "475f154148647d45e0f1324762fe5452094147085fddf2ccef4e9725c335b0c1"
  license "Zlib"

  livecheck do
    url "https://pwmt.org/projects/girara/download/"
    regex(/girara[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "667eb85183f6f2013a4e61592e368c8aa413b817b54e13e6947596fdd565c680"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  depends_on "glib"

  def install
    # Upstream defaults to c_std=c23, which GCC 13 (CI) rejects; c17 is equivalent here.
    system "meson", "setup", "build", "-Ddocs=disabled", "-Dc_std=c17", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <girara/girara.h>

      int main(void) {
        GiraraTemplate* obj = girara_template_new("home@test@");
        girara_template_add_variable(obj, "test");
        girara_template_set_variable_value(obj, "test", "brew");
        char* result = girara_template_evaluate(obj);
        g_object_unref(obj);
        if (result == NULL) return 1;
        printf("%s", result);
        g_free(result);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", *shell_output("pkgconf --cflags --libs girara").chomp.split
    assert_equal "homebrew", shell_output("./test")
  end
end
