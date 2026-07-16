class Oarfish < Formula
  desc "Long read RNA-seq quantification"
  homepage "https://github.com/COMBINE-lab/oarfish"
  url "https://github.com/COMBINE-lab/oarfish/archive/refs/tags/v0.10.3.tar.gz"
  sha256 "4fb1d8122ec9e052ca91f127feb374b9feb01b50e202590f7fe3f38b37070aff"
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
