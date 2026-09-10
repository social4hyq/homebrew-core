class Perl < Formula
  desc "Highly capable, feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.44.0.tar.xz"
  sha256 "505cf43912e9480495c344c70260452e32aa2a73c546a026b3f100053b23ce91"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]
  compatibility_version 1
  head "https://github.com/perl/perl5.git", branch: "blead"
  revision 2

  livecheck do
    url "https://www.cpan.org/src/#{version.major}.0/"
    regex(/href=.*?perl[._-]v?(\d+\.\d*[02468](?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "544d031401c4570a578a9f171f7797ab4ad0877d877ba24e0886b33eca802078"
  end

  depends_on "gdbm"

  # Prevent site_perl directories from being removed
  skip_clean "lib/perl5/site_perl"

  patch do
    file "Patches/perl/0001-add-ohos-support.patch"
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
