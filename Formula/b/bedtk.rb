class Bedtk < Formula
  desc "Simple toolset for BED files"
  homepage "https://github.com/lh3/bedtk"
  url "https://github.com/lh3/bedtk/archive/refs/tags/v1.2.tar.gz"
  sha256 "c0e1f454337dbd531659662ccce6c35831e7eec75ddf7b7751390b869e6ce9f0"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "686e67cd14f3a3e15b2aa7dfcc572b24cee12cc1b0dca1467d9f4c0e82bbd966"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make"
    bin.install "bedtk"
    pkgshare.install "test"
  end

  test do
    cp_r pkgshare/"test/.", testpath
    system bin/"bedtk", "flt", "test-anno.bed.gz", "test-iso.bed.gz"
  end
end
