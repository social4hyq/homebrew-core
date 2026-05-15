class Cpanminus < Formula
  desc "Get, unpack, build, and install modules from CPAN"
  homepage "https://github.com/miyagawa/cpanminus"
  # Don't use git tags, their naming is misleading
  url "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-1.7049.tar.gz"
  sha256 "b9ffb88e62a06aa91bd7d5a28ef6bdbb942608aea90e3969aa29b33640035214"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]
  version_scheme 1
  head "https://github.com/miyagawa/cpanminus.git", branch: "devel"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5bf353da3c9cec6c1cb57faef675df21e212706e59c082f85f7f2d42eac5aef0"
  end

  depends_on "perl" => :build

  def install
    cd "App-cpanminus" if build.head?

    system "perl", "Makefile.PL", "INSTALL_BASE=#{prefix}",
                                  "INSTALLSITEMAN1DIR=#{man1}",
                                  "INSTALLSITEMAN3DIR=#{man3}"
    system "make", "install"

    inreplace_files = [
      buildpath/"README",
      bin/"cpanm",
      lib/"perl5/App/cpanminus/fatscript.pm",
      lib/"perl5/App/cpanminus.pm",
      man3/"App::cpanminus.3",
    ]
    inreplace inreplace_files, "/usr/local", HOMEBREW_PREFIX, audit_result: build.stable?

    # Needed for dependents that might use Homebrew perl or system perl.
    inreplace bin/"cpanm", %r{^#!#{Regexp.escape(Formula["perl"].opt_bin)}/perl$}, "#!/usr/bin/env perl"
  end

  test do
    assert_match "cpan.metacpan.org", stable.url, "Don't use git tags, their naming is misleading"
    system bin/"cpanm", "--local-lib=#{testpath}/perl5", "Test::More"
  end
end
