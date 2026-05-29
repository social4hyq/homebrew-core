class Flye < Formula
  include Language::Python::Virtualenv

  desc "De novo assembler for single molecule sequencing reads using repeat graphs"
  homepage "https://github.com/mikolmogorov/Flye"
  url "https://github.com/mikolmogorov/Flye/archive/refs/tags/2.9.6.tar.gz"
  sha256 "f05a3889b1c7aafed4cc0ed1adc1f19c22618c1c7b97ab5f80d388c8192bd32a"
  license all_of: [
    "BSD-3-Clause",
    "Apache-2.0", # lib/libcuckoo
    "BSL-1.0",    # lib/lemon
    "CC-BY-3.0",  # src/common/memory_info.h
    "MIT",        # lib/{interval_tree,minimap2}
  ]
  head "https://github.com/mikolmogorov/Flye.git", branch: "flye"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72744ee8b9065f72af2d4cd36cb71f8cc34c905b78f70295967ea23a50b4b9dc"
  end

  depends_on "python@3.14"
  depends_on "samtools"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Replace bundled samtools
    rm_r(Dir["lib/samtools*"])
    (buildpath/"bin").write_exec_script Formula["samtools"].opt_bin/"samtools"
    (buildpath/"bin").install "bin/samtools" => "flye-samtools"
    chmod 0755, "bin/flye-samtools"

    # Workaround for arm64 Linux: https://github.com/mikolmogorov/Flye/pull/691
    ENV["arm_neon"] = ENV["aarch64"] = "1" if OS.linux? && Hardware::CPU.arm64?

    ENV.deparallelize
    venv = virtualenv_install_with_resources
    pkgshare.install_symlink venv.site_packages/"flye/tests/data"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/flye --version")
    system bin/"flye", "--pacbio-corr", pkgshare/"data/ecoli_500kb_reads_hifi.fastq.gz", "-o", testpath
    assert_path_exists "assembly.fasta"
  end
end
