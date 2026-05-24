class Libart < Formula
  desc "Library for high-performance 2D graphics"
  homepage "https://github.com/armon/libart"
  url "https://download.gnome.org/sources/libart_lgpl/2.3/libart_lgpl-2.3.21.tar.bz2"
  sha256 "fdc11e74c10fc9ffe4188537e2b370c0abacca7d89021d4d303afdf7fd7476fa"
  license "LGPL-2.0-or-later"

  # We use a common regex because libart doesn't use GNOME's "even-numbered
  # minor is stable" version scheme.
  livecheck do
    url :stable
    regex(/libart_lgpl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3da39f09e436f3573a89c562171b5f654c67d9ee0b74c55bc7588d157480d21d"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/libart2-config --version")

    (testpath/"test.c").write <<~EOS
      #include <libart_lgpl/art_svp.h>
      int main(void) {
        return 0;
      }
    EOS

    system ENV.cc, "-o", "test", "test.c", "-I#{include}/libart-2.0", "-L#{lib}", "-lart_lgpl_2"
    system "./test"
  end
end
