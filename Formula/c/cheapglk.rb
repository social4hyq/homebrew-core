class Cheapglk < Formula
  desc "Extremely minimal Glk library"
  homepage "https://www.eblong.com/zarf/glk/"
  url "https://www.eblong.com/zarf/glk/cheapglk-107.tar.gz"
  version "1.0.7"
  sha256 "87b9a19d741c71a8d3bffbb0fd7833410672006d3815717c70860e1681043d4c"
  license "MIT"

  livecheck do
    url :homepage
    regex(/href=.*?cheapglk[._-]v?(?:\d+(?:\.\d+)*)\.t[^>]+?>\s*?CheapGlk library v?(\d+(?:\.\d+)+)/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f1163a102b6f1f65cb64a6af4efbe3737786f0c10d1d8fc2ba6d64a42513e51"
  end

  keg_only "it conflicts with other Glk libraries"

  def install
    system "make"

    lib.install "libcheapglk.a"
    include.install "glk.h", "glkstart.h", "gi_blorb.h", "gi_dispa.h", "Make.cheapglk"
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
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcheapglk", "-o", "test"
    assert_match version.to_s, pipe_output("./test", "echo test", 0)
  end
end
