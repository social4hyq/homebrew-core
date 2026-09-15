class Sylph < Formula
  desc "Ultrafast taxonomic profiling and genome querying for metagenomic samples"
  homepage "https://github.com/bluenote-1577/sylph"
  url "https://github.com/bluenote-1577/sylph/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "dd4ba47906be7f3502b6bec88fa212ba5340b1eefced0192052ef0da82ca3a2d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b2b87d986c51959dd9a974b9577f9eec9921c94e89288b06167da5aff885c99"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "test_files"
  end

  test do
    cp_r pkgshare/"test_files/.", testpath
    system bin/"sylph", "sketch", "o157_reads.fastq.gz"
    assert_path_exists "o157_reads.fastq.gz.sylsp"
  end
end
