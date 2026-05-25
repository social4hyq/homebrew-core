class Gffread < Formula
  desc "GFF/GTF format conversions, region filtering, FASTA sequence extraction"
  homepage "https://github.com/gpertea/gffread"
  url "https://github.com/gpertea/gffread/releases/download/v0.12.9/gffread-0.12.9.tar.gz"
  sha256 "3ee1a3a2db938569bcccb1e8d908503392ebf0a3f203ddaff1b967b8ade614d1"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "758dd5465561a1b343b120b5eafbd80c2e6a4dbd3b6213d2334c9613af6b1a70"
  end

  def install
    system "make", "release"
    bin.install "gffread"
  end

  test do
    resource "test_gtf" do
      url "https://raw.githubusercontent.com/gpertea/gffread/4959f6b/examples/output/annotation.gtf"
      sha256 "f8dcf147dd451e994cebfe054e120ecbf19fd40f99ae9e9865a312097c228741"
    end
    testpath.install resource("test_gtf")
    system bin/"gffread", "-E", testpath/"annotation.gtf", "-o", "ann_simple.gff"
    assert_match "##gff-version 3", (testpath/"ann_simple.gff").read

    assert_match version.to_s, shell_output("#{bin}/gffread --version")
  end
end
