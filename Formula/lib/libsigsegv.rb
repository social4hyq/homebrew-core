class Libsigsegv < Formula
  desc "Library for handling page faults in user mode"
  homepage "https://www.gnu.org/software/libsigsegv/"
  url "https://ftpmirror.gnu.org/gnu/libsigsegv/libsigsegv-2.15.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libsigsegv/libsigsegv-2.15.tar.gz"
  sha256 "036855660225cb3817a190fc00e6764ce7836051bacb48d35e26444b8c1729d9"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21555d140783f9b330ea885df32a190c4a44be180ebd93601a030778811bb98d"
  end

  head do
    url "https://git.savannah.gnu.org/git/libsigsegv.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "./gitsub.sh", "pull" if build.head?
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-shared"
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    # Sourced from tests/efault1.c in tarball.
    (testpath/"test.c").write <<~C
      #include "sigsegv.h"

      #include <errno.h>
      #include <fcntl.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <unistd.h>

      const char *null_pointer = NULL;
      static int
      handler (void *fault_address, int serious)
      {
        abort ();
      }

      int
      main ()
      {
        if (open (null_pointer, O_RDONLY) != -1 || errno != EFAULT)
          {
            fprintf (stderr, "EFAULT not detected alone");
            exit (1);
          }

        if (sigsegv_install_handler (&handler) < 0)
          exit (2);

        if (open (null_pointer, O_RDONLY) != -1 || errno != EFAULT)
          {
            fprintf (stderr, "EFAULT not detected with handler");
            exit (1);
          }

        printf ("Test passed");
        return 0;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lsigsegv", "-o", "test"
    assert_match "Test passed", shell_output("./test")
  end
end
