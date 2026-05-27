class Liboil < Formula
  desc "C library of simple functions optimized for various CPUs"
  homepage "https://wiki.freedesktop.org/liboil/"
  url "https://liboil.freedesktop.org/download/liboil-0.3.17.tar.gz"
  sha256 "105f02079b0b50034c759db34b473ecb5704ffa20a5486b60a8b7698128bfc69"
  # Only liboil/ref/mt19937ar.c is BSD-3-Clause while rest is BSD-2-Clause.
  # The license for liboil/motovec/* is excluded as it is only used on PowerPC.
  license all_of: ["BSD-2-Clause", "BSD-3-Clause"]

  livecheck do
    url "https://liboil.freedesktop.org/download/"
    regex(/href=.*?liboil[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "97d4ad91978534374e9236a7671e9714a78fa2ec63ef85547bd52dae0a048614"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gtk-doc" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    ENV.append "CFLAGS", "-fheinous-gnu-extensions" if ENV.compiler == :clang

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <liboil/liboil.h>
      int main(int argc, char** argv) {
        oil_init();
        return 0;
      }
    C

    flags = ["-I#{include}/liboil-0.3", "-L#{lib}", "-loil-0.3"] + ENV.cflags.to_s.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
