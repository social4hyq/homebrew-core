class Texinfo < Formula
  desc "Official documentation format of the GNU project"
  homepage "https://www.gnu.org/software/texinfo/"
  url "https://ftpmirror.gnu.org/gnu/texinfo/texinfo-7.3.tar.xz"
  mirror "https://ftp.gnu.org/gnu/texinfo/texinfo-7.3.tar.xz"
  sha256 "51f74eb0f51cfa9873b85264dfdd5d46e8957ec95b88f0fb762f63d9e164c72e"
  license "GPL-3.0-or-later"
  compatibility_version 1

  uses_from_macos "ncurses"
  uses_from_macos "perl"

  on_linux do
    depends_on "libunistring"
  end

  def install
    system "./configure", "--disable-install-warnings", *std_configure_args
    system "make", "install"
    doc.install Dir["doc/refcard/txirefcard*"]
  end

  def post_install
    info_dir = HOMEBREW_PREFIX/"share/info/dir"
    info_dir.delete if info_dir.exist?
    info_dir.dirname.glob(["*.info", "*.info.gz"]) do |f|
      quiet_system("#{bin}/install-info", "--quiet", f, info_dir)
    end
  end

  test do
    (testpath/"test.texinfo").write <<~EOS
      @ifnottex
      @node Top
      @top Hello World!
      @end ifnottex
      @bye
    EOS

    system bin/"makeinfo", "test.texinfo"
    assert_match "Hello World!", (testpath/"test.info").read
  end
end
