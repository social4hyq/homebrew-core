class Bowtie2 < Formula
  desc "Fast and sensitive gapped read aligner"
  homepage "https://bowtie-bio.sourceforge.net/bowtie2/index.shtml"
  url "https://github.com/BenLangmead/bowtie2/archive/refs/tags/v2.5.5.tar.gz"
  sha256 "e38d1833ec235ca27fa57589d32d897c9addf87085b7cb7bc978662954662da2"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ed98ee15eccc819178d265271b1eca34be99a231ea9d955fc626c5793a5c36cc"
  end

  uses_from_macos "perl"
  uses_from_macos "python"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  on_arm do
    depends_on "simde" => :build
  end

  def install
    ENV.runtime_cpu_detection

    if OS.mac? && Hardware::CPU.intel?
      # Apple clang rejects "__builtin_cpu_supports(\"x86-64-v3\")".
      # Use AVX2 feature probing for runtime dispatch to the `-v256` binaries.
      inreplace "bowtie_main.cpp", '"x86-64-v3"', '"avx2"'
    end

    system "make", "install", "PREFIX=#{prefix}"
    pkgshare.install "example", "scripts"
  end

  test do
    system bin/"bowtie2-build",
           "#{pkgshare}/example/reference/lambda_virus.fa", "lambda_virus"
    assert_path_exists testpath/"lambda_virus.1.bt2", "Failed to create viral alignment lambda_virus.1.bt2"
  end
end
