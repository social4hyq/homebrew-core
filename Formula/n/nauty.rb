class Nauty < Formula
  desc "Automorphism groups of graphs and digraphs"
  homepage "https://pallini.di.uniroma1.it/"
  url "https://pallini.di.uniroma1.it/nauty2_9_3.tar.gz"
  mirror "https://users.cecs.anu.edu.au/~bdm/nauty/nauty2_9_3.tar.gz"
  sha256 "9fc4edae04f88a0f5883985be3b39cf7f898fd6cc96e96b9ee25452743cc1b5b"
  license "Apache-2.0"
  version_scheme 1

  livecheck do
    url :homepage
    regex(/Current\s+?version:\s*?v?(\d+(?:[._]\d+)+(?:r\d+)?)/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match.first.tr("_R", ".r") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b06813ba74c19994bed686cda0f09985d3c9c3495eebc4b76afb642c5f9f2119"
  end

  def install
    system "./configure", "--enable-tls", "--includedir=#{include}/nauty", *std_configure_args
    system "make", "all", "TLSlibs"
    system "make", "install", "TLSinstall"

    doc.install "nug#{version.major_minor.to_s.tr(".", "")}.pdf", "README", Dir["*.txt"]

    # Ancillary source files listed in README
    pkgshare.install %w[sumlines.c sorttemplates.c bliss2dre.c poptest.c]
  end

  test do
    # from ./runalltests
    out1 = shell_output("#{bin}/geng -ud1D7t 11 2>&1")
    out2 = pipe_output("#{bin}/countg --nedDr -q", shell_output("#{bin}/genrang -r3 114 100"))

    assert_match "92779 graphs generated", out1
    assert_match "100 graphs : n=114; e=171; mindeg=3; maxdeg=3; regular", out2

    # test that the library is installed and linkable-against
    (testpath/"test.c").write <<~C
      #define MAXN 1000
      #include <nauty/nauty.h>

      int main()
      {
        int n = 12345;
        int m = SETWORDSNEEDED(n);
        nauty_check(WORDSIZE, m, n, NAUTYVERSIONID);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}/nauty", "-L#{lib}", "-lnauty", "-o", "test"
    system "./test"
  end
end
