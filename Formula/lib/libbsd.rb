class Libbsd < Formula
  desc "Utility functions from BSD systems"
  homepage "https://libbsd.freedesktop.org/"
  url "https://libbsd.freedesktop.org/releases/libbsd-0.12.2.tar.xz"
  sha256 "b88cc9163d0c652aaf39a99991d974ddba1c3a9711db8f1b5838af2a14731014"
  license all_of: [
    "BSD-3-Clause",
    "BSD-2-Clause",
    "Beerware",
    "ISC",
    "libutil-David-Nugent",
    "MIT",
    :public_domain,
  ]
  revision 1

  livecheck do
    url "https://libbsd.freedesktop.org/releases/"
    regex(/href=.*?libbsd[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0c44771fa2ab85d11a0aca73484d4a11904500a838721babd3ab037241481d7d"
  end

  head do
    url "https://gitlab.freedesktop.org/libbsd/libbsd.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  on_linux do
    depends_on "libmd"
  end

  # Add /proc/self/comm fallback for getprogname() on Linux without glibc
  patch do
    file "Patches/libbsd/progname.patch"
  end

  def install
    system "./autogen" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <bsd/stdlib.h>

      int main(void) {
        const char *q;
        long long val = strtonum("1", 0, 10, &q);
        if (q != NULL) {
          printf("%s", q);
          return 1;
        }
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", lib/shared_library("libbsd", version.major.to_s)
    system "./test"
  end
end
