class Abpoa < Formula
  desc "SIMD-based C library for fast partial order alignment using adaptive band"
  homepage "https://github.com/yangao07/abPOA"
  url "https://github.com/yangao07/abPOA/releases/download/v1.5.7/abPOA-v1.5.7.tar.gz"
  sha256 "9c5e7649a4268223ef1fec0318b3f4fa7c118ffa2daac124051c7961e6894bc8"
  license "MIT"
  head "https://github.com/yangao07/abPOA.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afb158ea0927e79e285807183af163e2ad036002cdd3d4ffcbc90db57a2e706f"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make"
    bin.install "bin/abpoa"
    pkgshare.install "test_data"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/abpoa --version")
    cp_r pkgshare/"test_data/.", testpath
    assert_match ">Consensus_sequence", shell_output("#{bin}/abpoa seq.fa")
  end
end
