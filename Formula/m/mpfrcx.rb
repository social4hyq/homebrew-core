class Mpfrcx < Formula
  desc "Arbitrary precision library for arithmetic of univariate polynomials"
  homepage "https://www.multiprecision.org/mpfrcx/"
  url "https://www.multiprecision.org/downloads/mpfrcx-0.6.3.tar.gz"
  sha256 "9da9b3614c0a3e00e6ed2b82fc935d1c838d97074dc59cb388f8fafbe3db8594"
  license "GPL-3.0-or-later"
  head "https://gitlab.inria.fr/enge/mpfrcx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b53a81bbb8f50829fd06b470f22ce1d87b810be5c1cf5299bb16efc29a5e3291"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"

  def install
    # Regenerate configure to avoid building libraries with flat namespaces
    system "autoreconf", "--force", "--install", "--verbose"

    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"

    (pkgshare/"tests").install Dir["tests/tc_*.c"]
  end

  test do
    Dir[pkgshare/"tests/*"].each do |src|
      testname = File.basename(src, ".c")
      system ENV.cc, src, "-I#{include}", "-L#{lib}",
             "-L#{Formula["gmp"].opt_lib}", "-L#{Formula["libmpc"].opt_lib}", "-L#{Formula["mpfr"].opt_lib}",
             "-lmpfrcx", "-lgmp", "-lmpc", "-lmpfr",
             "-o", testname
      system testpath/testname
    end
  end
end
