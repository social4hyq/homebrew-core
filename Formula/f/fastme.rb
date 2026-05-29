class Fastme < Formula
  desc "Accurate and fast distance-based phylogeny inference program"
  homepage "http://www.atgc-montpellier.fr/fastme/"
  url "https://gite.lirmm.fr/atgc/FastME/raw/v2.1.6.3/tarball/fastme-2.1.6.3.tar.gz"
  sha256 "09a23ea94e23c0821ab75f426b410ec701dac47da841943587443a25b2b85030"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    url "https://gite.lirmm.fr/atgc/FastME.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be1cd1169b7f00df74c059f6ecdb07ba7ddf6a4e189743814f0c4df911d70058"
  end

  on_macos do
    depends_on "libomp"
  end

  def install
    if OS.mac?
      ENV["OPENMP_CFLAGS"] = "-Xpreprocessor -fopenmp"
      ENV["OPENMP_LDFLAG"] = "-lomp"
    end
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.dist").write <<~EOS
      4
      A 0.0 1.0 2.0 4.0
      B 1.0 0.0 3.0 5.0
      C 2.0 3.0 0.0 6.0
      D 4.0 5.0 6.0 0.0
    EOS

    system bin/"fastme", "-i", "test.dist"
    assert_path_exists testpath/"test.dist_fastme_tree.nwk"
  end
end
