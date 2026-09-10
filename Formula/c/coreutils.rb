class Coreutils < Formula
  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils/"
  url "https://ftpmirror.gnu.org/gnu/coreutils/coreutils-9.11.tar.xz"
  mirror "https://ftp.gnu.org/gnu/coreutils/coreutils-9.11.tar.xz"
  sha256 "394024eda0a5955217ceda9cd1201e65dc8fa3aa29c2951135a49521d57c3cc3"
  license "GPL-3.0-or-later"
  revision 3
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "625576b003c86e35412110956b09ff0f3198d8d877f511f280fdeba6f216e13f"
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
