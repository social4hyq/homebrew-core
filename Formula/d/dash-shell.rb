class DashShell < Formula
  desc "POSIX-compliant descendant of NetBSD's ash (the Almquist SHell)"
  homepage "http://gondor.apana.org.au/~herbert/dash/"
  url "https://cdn.netbsd.org/pub/pkgsrc/distfiles/dash-0.5.13.4.tar.gz"
  mirror "http://gondor.apana.org.au/~herbert/dash/files/dash-0.5.13.4.tar.gz"
  sha256 "d10dfd41cda59165560db39ca915c2c4a7636fff04281d8d2df77ad92c753e2b"
  license "BSD-3-Clause"
  head "https://git.kernel.org/pub/scm/utils/dash/dash.git", branch: "master"

  livecheck do
    url "http://gondor.apana.org.au/~herbert/dash/files/"
    regex(/href=.*?dash[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8833c1cf672190706cb4125ece903672d9241c2809bbfaaae0fa9dd38623ab2f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libedit"

  def install
    ENV["ac_cv_func_stat64"] = "no" if OS.mac? && Hardware::CPU.arm?
    system "./autogen.sh" if build.head?
    system "./configure", "--with-libedit", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"dash", "-c", "echo Hello!"
  end
end
