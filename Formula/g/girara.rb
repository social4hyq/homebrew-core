class Girara < Formula
  desc "Common components for zathura"
  homepage "https://pwmt.org/projects/girara/"
  url "https://pwmt.org/projects/girara/download/girara-2026.07.18.tar.xz"
  sha256 "d7255635776a45d42d1e555aa425ab96caf23755442474cf240cbac966d8502f"
  license "Zlib"
  revision 1

  livecheck do
    url "https://pwmt.org/projects/girara/download/"
    regex(/girara[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a9a0dc73c01b961394a32f59225a0d0eb019cb933c03972583df2b3f3224abe0"
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
