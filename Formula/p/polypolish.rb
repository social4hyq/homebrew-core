class Polypolish < Formula
  desc "Short-read polishing tool for long-read assemblies"
  homepage "https://github.com/rrwick/Polypolish"
  url "https://github.com/rrwick/Polypolish/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "4e00dce9e3c1a224fdfe16b0e3632df13a250f43a36c302fd579683bbd325086"
  license "GPL-3.0-or-later"
  head "https://github.com/rrwick/Polypolish.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "47288f81b547c47efd819661b0d33b9c7d3f337e9829e783db646aa6d208a713"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.fasta").write <<~FASTA
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
    FASTA
    (testpath/"test.sam").write <<~SAM
      @HD\tVN:1.6\tSO:unsorted
      @SQ\tSN:U00096.2:1-70\tLN:70
      read1\t0\tU00096.2:1-70\t1\t60\t20M\t*\t0\t0\tAGCTTTTCATTCTGACTGCA\tIIIIIIIIIIIIIIIIIIII\tNM:i:0
    SAM

    output = shell_output("#{bin}/polypolish polish test.fasta test.sam")
    assert_match "polypolish", output
  end
end
