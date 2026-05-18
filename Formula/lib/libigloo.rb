class Libigloo < Formula
  desc "Generic C framework used and developed by the Icecast project"
  homepage "https://icecast.org/"
  url "https://downloads.xiph.org/releases/igloo/libigloo-0.9.5.tar.gz"
  sha256 "ea22e9119f7a2188810f99100c5155c6762d4595ae213b9ac29e69b4f0b87289"
  license "LGPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "03e47c206f9e0416c51161093f1323f2cfd750de9c64986c0927d9db6df6441e"
  end

  head do
    url "https://gitlab.xiph.org/xiph/icecast-libigloo.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "rhash"

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <igloo/tap.h>

      int main(void) {
        igloo_tap_init();
        igloo_tap_exit_on(igloo_TAP_EXIT_ON_FIN, NULL);
        igloo_tap_fin();
        return EXIT_FAILURE;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-ligloo"
    system "./test"
  end
end
