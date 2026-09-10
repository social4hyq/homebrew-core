class GnuTar < Formula
  desc "GNU version of the tar archiving utility"
  homepage "https://www.gnu.org/software/tar/"
  url "https://ftpmirror.gnu.org/gnu/tar/tar-1.35.tar.gz"
  mirror "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.gz"
  sha256 "14d55e32063ea9526e057fbf35fcabd53378e769787eff7919c3755b02d2b57e"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "df64ce2a6d1533dbd0816c46c71fc394dba7f74b6a1f30f8e19b57417a4591dc"
  end

  head do
    url "https://git.savannah.gnu.org/git/tar.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --disable-nls
    ]

    args << if OS.mac?
      "--program-prefix=g"
    else
      "--without-selinux"
    end

    args << "FORCE_UNSAFE_CONFIGURE=1"

    # iconv is detected during configure process but -liconv is missing
    # from LDFLAGS as of gnu-tar 1.35. Remove once iconv linking works
    # without this. See https://savannah.gnu.org/bugs/?64441.
    # fix commit, https://git.savannah.gnu.org/cgit/tar.git/commit/?id=8632df39, remove in next release
    ENV.append "LDFLAGS", "-liconv" if OS.mac?

    system "./bootstrap" if build.head?
    system "./configure", *args
    system "make", "install"

    return unless OS.mac?

    # Symlink the executable into libexec/gnubin as "tar"
    (libexec/"gnubin").install_symlink bin/"gtar" => "tar"
    (libexec/"gnuman/man1").install_symlink man1/"gtar.1" => "tar.1"
    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "tar" has been installed as "gtar".
        If you need to use it as "tar", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    (testpath/"test").write("test")
    if OS.mac?
      system bin/"gtar", "-czvf", "test.tar.gz", "test"
      assert_match "test", shell_output("#{bin}/gtar -xOzf test.tar.gz")
      assert_match "test", shell_output("#{opt_libexec}/gnubin/tar -xOzf test.tar.gz")
    else
      system bin/"tar", "-czvf", "test.tar.gz", "test"
      assert_match "test", shell_output("#{bin}/tar -xOzf test.tar.gz")
    end
  end
end
