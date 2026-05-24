class Skani < Formula
  desc "Fast, robust ANI and aligned fraction for (metagenomic) genomes and contigs"
  homepage "https://github.com/bluenote-1577/skani"
  url "https://github.com/bluenote-1577/skani/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "5cae2fc3b8c57881fd9d3494c372eb8c8703eb69900513bfaef01f8892c55ae0"
  license "MIT"
  head "https://github.com/bluenote-1577/skani.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b41a694bcafa30318625e5df95c2ceee04c3d011d91af9f8b7fe517597beac4b"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "test_files"
  end

  test do
    cp_r pkgshare/"test_files/.", testpath
    output = shell_output("#{bin}/skani dist e.coli-EC590.fasta e.coli-K12.fasta")
    assert_match "complete sequence", output
  end
end
