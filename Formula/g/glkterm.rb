class Glkterm < Formula
  desc "Terminal-window Glk library"
  homepage "https://www.eblong.com/zarf/glk/"
  url "https://www.eblong.com/zarf/glk/glkterm-104.tar.gz"
  version "1.0.4"
  sha256 "473d6ef74defdacade2ef0c3f26644383e8f73b4f1b348e37a9bb669a94d927e"
  license "Glulxe"

  livecheck do
    url :homepage
    regex(/href=.*?glkterm[._-]v?(?:\d+(?:\.\d+)*)\.t[^>]+?>\s*?GlkTerm library v?(\d+(?:\.\d+)+)/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f8d0d3f23a7fd66cc0f3343fd1a63bf4dd4a9e1d352b8cc18f24cdafb5f268e"
  end

  keg_only "it conflicts with other Glk libraries"

  uses_from_macos "ncurses"

  def install
    system "make"

    lib.install "libglkterm.a"
    include.install "glk.h", "glkstart.h", "gi_blorb.h", "gi_dispa.h", "Make.glkterm"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "glk.h"
      #include "glkstart.h"

      glkunix_argumentlist_t glkunix_arguments[] = {
          { NULL, glkunix_arg_End, NULL }
      };

      int glkunix_startup_code(glkunix_startup_t *data)
      {
          return TRUE;
      }

      void glk_main()
      {
          glk_exit();
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lglkterm", "-lncurses", "-o", "test"
    system "echo test | ./test"
  end
end
