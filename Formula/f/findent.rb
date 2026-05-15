class Findent < Formula
  desc "Indent and beautify Fortran sources and generate dependency information"
  homepage "https://www.ratrabbit.nl/ratrabbit/findent/index.html"
  url "https://downloads.sourceforge.net/project/findent/findent-4.3.6.tar.gz"
  mirror "https://www.ratrabbit.nl/downloads/findent/findent-4.3.6.tar.gz"
  sha256 "72d834d8ff0fdd1dbb942a6fded20b499e62927d956b6e631ce588b917c838d4"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(%r{url=.*?/findent[._-]v?(\d+(?:\.\d+)+)\.(?:t|zip)}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "916c5fc9c76252a53947881c878298869d9c62494df4270e1bf2daf641e9b138"
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
    (pkgshare/"test").install %w[test/progfree.f.in test/progfree.f.try.f.ref]
  end

  test do
    cp_r pkgshare/"test/progfree.f.in", testpath
    cp_r pkgshare/"test/progfree.f.try.f.ref", testpath

    flags = File.open(testpath/"progfree.f.in", &:readline).sub(/ *! */, "").chomp
    system bin/"findent #{flags} < progfree.f.in > progfree.f.out.f90"
    assert_path_exists testpath/"progfree.f.out.f90"
    assert compare_file(testpath/"progfree.f.try.f.ref", testpath/"progfree.f.out.f90")
  end
end
