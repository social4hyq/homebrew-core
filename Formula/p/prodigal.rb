class Prodigal < Formula
  desc "Microbial gene prediction"
  homepage "https://github.com/hyattpd/Prodigal"
  url "https://github.com/hyattpd/Prodigal/archive/refs/tags/v2.6.3.tar.gz"
  sha256 "89094ad4bff5a8a8732d899f31cec350f5a4c27bcbdd12663f87c9d1f0ec599f"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "762f30a4ec237d5ed6afb1ee10bbf5be23f12d4c5d564a96e9cd495679e281b8"
  end

  # Prodigal will have incorrect output if compiled with certain compilers.
  # This will be fixed in the next release. Also see:
  # https://github.com/hyattpd/Prodigal/issues/34
  # https://github.com/hyattpd/Prodigal/issues/41
  # https://github.com/hyattpd/Prodigal/pull/35
  patch do
    on_linux do
      url "https://github.com/hyattpd/Prodigal/commit/cbbb5db21d120f100724b69d5212cf1275ab3759.patch?full_index=1"
      sha256 "fd292c0a98412a7f2ed06d86e0e3f96a9ad698f6772990321ad56985323b99a6"
    end
  end

  # Avoid undefined behavior accessing array at index -1
  patch :DATA

  def install
    system "make", "install", "INSTALLDIR=#{bin}"
  end

  test do
    fasta = <<~EOS
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
    EOS
    assert_match "CDS", pipe_output("#{bin}/prodigal -q -p meta", fasta, 0)
  end
end

__END__
diff --git a/main.c b/main.c
index 0834a07..712135d 100644
--- a/main.c
+++ b/main.c
@@ -556,7 +556,7 @@ int main(int argc, char *argv[]) {
         score_nodes(seq, rseq, slen, nodes, nn, meta[i].tinf, closed, is_meta);
         record_overlapping_starts(nodes, nn, meta[i].tinf, 1);
         ipath = dprog(nodes, nn, meta[i].tinf, 1);
-        if(nodes[ipath].score > max_score) {
+        if(ipath >= 0 && nodes[ipath].score > max_score) {
           max_phase = i;
           max_score = nodes[ipath].score;
           eliminate_bad_genes(nodes, ipath, meta[i].tinf);
