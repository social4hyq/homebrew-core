class Perl < Formula
  desc "Highly capable, feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.42.2.tar.xz"
  sha256 "0a585eeb9e363c0f80482ddb3571625250c2c86aeb408853e8ea50805cfb14bb"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]
  compatibility_version 1
  head "https://github.com/perl/perl5.git", branch: "blead"

  livecheck do
    url "https://www.cpan.org/src/#{version.major}.0/"
    regex(/href=.*?perl[._-]v?(\d+\.\d*[02468](?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2aaccc551f17ebc74ee17fb01dc56bcd715c842e306f9599abbcfb900274e02c"
  end

  depends_on "gdbm"

  # Prevent site_perl directories from being removed
  skip_clean "lib/perl5/site_perl"

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/perl/0001-add-ohos-support.patch"
    sha256 "ee18043946dcf6ab99c1ae9dbb89fb829ec5bd3eb1ff07d53ad82ae094ec7a50"
  end

  def install
    args = %W[
      -des
      -Dinstallstyle=lib/perl5
      -Dinstallprefix=#{prefix}
      -Dprefix=#{opt_prefix}
      -Dprivlib=#{opt_lib}/perl5/#{version.major_minor}
      -Dsitelib=#{opt_lib}/perl5/site_perl/#{version.major_minor}
      -Dotherlibdirs=#{HOMEBREW_PREFIX}/lib/perl5/site_perl/#{version.major_minor}
      -Dvendorlib=#{HOMEBREW_PREFIX}/lib/perl5/vendor_perl/#{version.major_minor}
      -Dvendorprefix=#{HOMEBREW_PREFIX}
      -Dperlpath=#{opt_bin}/perl
      -Dstartperl=#!#{opt_bin}/perl
      -Dman1dir=#{opt_share}/man/man1
      -Dman3dir=#{opt_share}/man/man3
      -Duseshrplib
      -Duselargefiles
      -Dusethreads
    ]
    args << "-Dusedevel" if build.head?

    # On macOS, we can use Apple's system library to support DB_File module.
    # On Linux, we explicitly exclude bundled DB_File to avoid opportunistic
    # linkage to Berkeley DB. Dependents and users can install it from CPAN.
    args << "-Ui_db" unless OS.mac?

    system "./Configure", *args
    system "make"
    system "make", "install"
  end

  def caveats
    s = <<~EOS
      By default non-brewed cpan modules are installed to the Cellar. If you wish
      for your modules to persist across updates we recommend using `local::lib`.

      You can set that up like this:
        PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib
      And add the following to your shell profile e.g. ~/.profile or ~/.zshrc
        eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
    EOS
    on_linux do
      s += <<~EOS

        Bundled DB_File module was not installed. If needed, you can install it from CPAN.
      EOS
    end
    s
  end

  test do
    (testpath/"test.pl").write "print 'Perl is not an acronym, but JAPH is a Perl acronym!';"
    system bin/"perl", "test.pl"
  end
end
