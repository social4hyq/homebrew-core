class Pod2man < Formula
  desc "Perl documentation generator"
  homepage "https://www.eyrie.org/~eagle/software/podlators/"
  url "https://archives.eyrie.org/software/perl/podlators-v6.1.1.tar.xz"
  sha256 "a28027ac17848912ab2b14544fd457e28269e7b3f8423d72526556f9779b1807"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  livecheck do
    url "https://archives.eyrie.org/software/perl/"
    regex(/href=.*?podlators[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f85f42e18874be5083358f1477d035501152723f3efe65765f2c32398f6ee97c"
  end

  keg_only "it conflicts with the pod2man that ships with Perl"

  depends_on "perl"

  resource "Pod::Simple" do
    url "https://cpan.metacpan.org/authors/id/K/KH/KHW/Pod-Simple-3.45.tar.gz"
    sha256 "8483bb95cd3e4307d66def092a3779f843af772482bfdc024e3e00d0c4db0cfa"
  end

  def install
    resource("Pod::Simple").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make"
      system "make", "install"
    end
    ENV.prepend_path "PERL5LIB", libexec/"lib/perl5"

    system "perl", "Makefile.PL", "INSTALL_BASE=#{prefix}",
                   "INSTALLSITEMAN1DIR=#{man1}", "INSTALLSITEMAN3DIR=#{man3}"
    system "make"
    system "make", "install"
    bin.env_script_all_files libexec/"bin", PERL5LIB: "#{lib}/perl5:#{libexec}/lib/perl5"

    # Rewrite the perl shebang so the installed scripts use the Homebrew perl
    # instead of the absolute perl path baked in at build time (which may not
    # exist on the install machine).
    perl_bin = Formula["perl"].opt_bin/"perl"
    libexec.glob("bin/*").each do |cmd|
      next unless cmd.file? && cmd.executable?
      inreplace cmd, %r{^#!.*perl\b}, "#!#{perl_bin}"
    end
  end

  test do
    (testpath/"test.pod").write "=head2 Test heading\n"
    manpage = shell_output("#{bin}/pod2man #{testpath}/test.pod")
    assert_match '.SS "Test heading"', manpage
    assert_match "Pod::Man v#{version}", manpage
  end
end
