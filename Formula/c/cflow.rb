class Cflow < Formula
  desc "Generate call graphs from C code"
  homepage "https://www.gnu.org/software/cflow/"
  url "https://ftpmirror.gnu.org/gnu/cflow/cflow-1.8.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/cflow/cflow-1.8.tar.bz2"
  sha256 "8321627b55b6c7877f6a43fcc6f9f846a94b1476a081a035465f7a78d3499ab8"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8939f9f90eca3d4c51f00050aad6f25a5274a757fb302e11e21747e39c3001e"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--infodir=#{info}",
                          "--disable-debug",
                          "--disable-dependency-tracking",
                          "--with-lispdir=#{elisp}"

    # Replace C++11 attribute syntax with GCC-style attribute for Clang compatibility
    if OS.mac? && DevelopmentTools.clang_build_version >= 1500
      inreplace "config.h", /\[\[__maybe_unused__\]\]/, "__attribute__((__unused__))"
    end

    system "make", "install"
  end

  test do
    (testpath/"whoami.c").write <<~C
      #include <pwd.h>
      #include <sys/types.h>
      #include <stdio.h>
      #include <stdlib.h>

      int
      who_am_i (void)
      {
        struct passwd *pw;
        char *user = NULL;

        pw = getpwuid (geteuid ());
        if (pw)
          user = pw->pw_name;
        else if ((user = getenv ("USER")) == NULL)
          {
            fprintf (stderr, "I don't know!\n");
            return 1;
          }
        printf ("%s\n", user);
        return 0;
      }

      int
      main (int argc, char **argv)
      {
        if (argc > 1)
          {
            fprintf (stderr, "usage: whoami\n");
            return 1;
          }
        return who_am_i ();
      }
    C

    assert_match "getpwuid()", shell_output("#{bin}/cflow --main who_am_i #{testpath}/whoami.c")
  end
end
