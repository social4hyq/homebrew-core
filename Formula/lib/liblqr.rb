class Liblqr < Formula
  desc "C/C++ seam carving library"
  homepage "https://liblqr.wikidot.com/"
  license "LGPL-3.0-only"
  compatibility_version 1
  head "https://github.com/carlobaldassi/liblqr.git", branch: "master"

  stable do
    url "https://github.com/carlobaldassi/liblqr/archive/refs/tags/v0.4.3.tar.gz"
    sha256 "64b0c4ac76d39cca79501b3f53544af3fc5f72b536ac0f28d2928319bfab6def"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fe070580f55ee593aa0d21f65d945c5bb19cc8cb6cb2b574d4a26b2166507d95"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "./configure", "--enable-install-man", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <lqr.h>

      int main() {
        guchar* buffer = calloc(1, sizeof(guchar));

        LqrCarver *carver = lqr_carver_new(buffer, 1, 1, 1);
        if (carver == NULL) return 1;

        lqr_carver_destroy(carver);

        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test",
                   "-I#{include}/lqr-1",
                   "-I#{Formula["glib"].opt_include}/glib-2.0",
                   "-I#{Formula["glib"].opt_lib}/glib-2.0/include",
                   "-L#{lib}", "-llqr-1"
    system "./test"
  end
end
