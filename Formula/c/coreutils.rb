class Coreutils < Formula
  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils/"
  url "https://ftpmirror.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz"
  mirror "https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz"
  sha256 "a480198559733e9b3da999e90543ac6f888a2caa544d8d664c5a1f17e528e210"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5541d20cd090326f3522140e905429f8e15218050b812c21d886684b8ecae449"
  end

  head do
    url "https://git.savannah.gnu.org/git/coreutils.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "gettext" => :build
    depends_on "texinfo" => :build
    depends_on "wget" => :build
    depends_on "xz" => :build
  end

  depends_on "gmp"
  uses_from_macos "gperf" => :build

  on_sonoma :or_older do
    conflicts_with "md5sha1sum", because: "both install `md5sum` and `sha1sum` binaries"
  end

  patch do
    file "Patches/coreutils/0001-port-gnulib-to-ohos.patch"
  end

  patch do
    file "Patches/coreutils/0002-cp-ignore-hole-punch-eperm-eacces.patch"
  end

  # https://github.com/Homebrew/homebrew-core/pull/36494
  def breaks_macos_users
    %w[dir dircolors vdir]
  end

  def install
    ENV.runtime_cpu_detection
    system "./bootstrap" if build.head?

    args = %W[
      --prefix=#{prefix}
      --with-libgmp
      --without-selinux
      ac_cv_func_vmsplice=no
      FORCE_UNSAFE_CONFIGURE=1
    ]

    system "./configure", *args
    system "make", "install"
  end

  test do
    (testpath/"test").write("test")
    (testpath/"test.sha1").write("a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 test")
    system bin/"sha1sum", "-c", "test.sha1"
    system bin/"ln", "-f", "test", "test.sha1"
  end
end
