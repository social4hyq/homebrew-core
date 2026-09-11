class Vcftools < Formula
  desc "Tools for working with VCF files"
  homepage "https://vcftools.github.io/"
  url "https://github.com/vcftools/vcftools/releases/download/v0.1.17/vcftools-0.1.17.tar.gz"
  sha256 "b9e0e1c3e86533178edb35e02c6c4de9764324ea0973bebfbb747018c2d2a42c"
  license "LGPL-3.0-only"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9cb81e76f90827fc6d187c7de68e2bfc4807089717183da50629c7b9af327118"
  end

  depends_on "pkgconf" => :build
  depends_on "htslib"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--disable-silent-rules",
                          "--with-pmdir=lib/perl5/site_perl",
                          *std_configure_args
    system "make", "install"

    bin.env_script_all_files(libexec/"bin", PERL5LIB: lib/"perl5/site_perl")
  end

  test do
    (testpath/"test.vcf").write <<~EOS
      ##fileformat=VCFv4.0
      #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
      1	1	.	A	C	10	PASS	.
    EOS

    system bin/"vcf-validator", "test.vcf"
  end
end
