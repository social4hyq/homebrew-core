class Grep < Formula
  desc "GNU grep, egrep and fgrep"
  homepage "https://www.gnu.org/software/grep/"
  url "https://ftpmirror.gnu.org/gnu/grep/grep-3.12.tar.xz"
  mirror "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz"
  sha256 "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "910887514a719318c23bebfddb3f2e497d94f627f51b789fbdea0ad69fe4928e"
  end

  head do
    url "https://git.savannah.gnu.org/git/grep.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
    depends_on "texinfo" => :build
    depends_on "wget" => :build

    uses_from_macos "gperf" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "pcre2"

  def install
    system "./bootstrap" if build.head?

    args = %W[
      --disable-nls
      --infodir=#{info}
      --mandir=#{man}
      --with-packager=Homebrew
    ]

    args << "--program-prefix=g" if OS.mac?
    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"

    if OS.mac?
      bin.children.each do |file|
        (libexec/"gnubin").install_symlink file => file.basename.to_s.delete_prefix("g")
      end
      man1.children.each do |file|
        (libexec/"gnuman/man1").install_symlink file => file.basename.to_s.delete_prefix("g")
      end
    end

    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  def caveats
    on_macos do
      <<~EOS
        All commands have been installed with the prefix "g".
        If you need to use these commands with their normal names, you
        can add a "gnubin" directory to your PATH from your bashrc like:
          PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    text_file = testpath/"file.txt"
    text_file.write "This line should be matched"

    if OS.mac?
      grepped = shell_output("#{bin}/ggrep -P match #{text_file}")
      assert_match "should be matched", grepped

      grepped = shell_output("#{opt_libexec}/gnubin/grep -P match #{text_file}")
    else
      grepped = shell_output("#{bin}/grep -P match #{text_file}")
    end
    assert_match "should be matched", grepped
  end
end
