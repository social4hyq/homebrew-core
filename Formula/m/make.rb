class Make < Formula
  desc "Utility for directing compilation"
  homepage "https://www.gnu.org/software/make/"
  url "https://ftpmirror.gnu.org/gnu/make/make-4.4.1.tar.lz"
  mirror "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.lz"
  sha256 "8814ba072182b605d156d7589c19a43b89fc58ea479b9355146160946f8cf6e9"
  license "GPL-3.0-only"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7131812a97fb8aae0915acfb5e542745aa3b37a898c9f03c0b229ed0da734d2"
  end

  head do
    url "https://git.savannah.gnu.org/git/make.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build # for autopoint
    depends_on "libtool" => :build
    depends_on "texinfo" => :build
    depends_on "wget" => :build # used by autopull

    uses_from_macos "m4" => :build

    fails_with :clang # fails with invalid arguments sent to compiler
  end

  def install
    if build.head?
      system "./autopull.sh" # downloads gnulib files from git that autogen.sh needs
      system "./autogen.sh"
    end

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
    ]

    args << "--program-prefix=g" if OS.mac?
    system "./configure", *args
    system "make", "install"

    if OS.mac?
      (libexec/"gnubin").install_symlink bin/"gmake" =>"make"
      (libexec/"gnuman/man1").install_symlink man1/"gmake.1" => "make.1"
    end

    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "make" has been installed as "gmake".
        If you need to use it as "make", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    (testpath/"Makefile").write <<~MAKE
      default:
      	@echo Homebrew
    MAKE

    if OS.mac?
      assert_equal "Homebrew\n", shell_output(bin/"gmake")
      assert_equal "Homebrew\n", shell_output(libexec/"gnubin/make")
    else
      assert_equal "Homebrew\n", shell_output(bin/"make")
    end
  end
end
