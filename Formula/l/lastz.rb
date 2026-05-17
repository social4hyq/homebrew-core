class Lastz < Formula
  desc "Pairwise aligner for DNA sequences"
  homepage "https://lastz.github.io/lastz/"
  url "https://github.com/lastz/lastz/archive/refs/tags/1.04.52.tar.gz"
  sha256 "274bf0d774e3f4da87c23ca0b5cc4269f3dcaecf71a1c6289d426e24fbccf4c8"
  license "MIT"
  head "https://github.com/lastz/lastz.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84ec01131a70926efded8ae820017d48d763716ccdd304725bad2d97f559f38b"
  end

  def install
    system "make", "install", "definedForAll=-Wall", "LASTZ_INSTALL=#{bin}"
    doc.install "README.lastz.html"
    pkgshare.install "test_data", "tools"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lastz --version", 1)
    assert_match "MAF", shell_output("#{bin}/lastz --help=formats", 1)
    dir = pkgshare/"test_data"
    assert_match "#:lav", shell_output("#{bin}/lastz #{dir}/pseudocat.fa #{dir}/pseudopig.fa")
  end
end
