class Oarfish < Formula
  desc "Long read RNA-seq quantification"
  homepage "https://github.com/COMBINE-lab/oarfish"
  url "https://github.com/COMBINE-lab/oarfish/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "b7d3dc76c032ffddf073254fa200c0282476852514845d46e0109bcdb038a145"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c613b8271d458d0bf31864774d652ff4f066cb76d8483fbbfb6e71e43af22c89"
  end

  depends_on "rust" => :build

  uses_from_macos "bzip2"
  uses_from_macos "zlib"

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "test_data"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oarfish --version")

    cp_r pkgshare/"test_data/SIRV_isoforms_multi-fasta_170612a.fasta", testpath/"test.fasta"
    system bin/"oarfish", "--reads", "test.fasta", "--annotated", "test.fasta",
                          "--seq-tech", "ont-cdna", "--output", "sample"
    assert_path_exists "sample.quant"
  end
end
