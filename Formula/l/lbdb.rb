class Lbdb < Formula
  desc "Little brother's database for the mutt mail reader"
  homepage "https://www.spinnaker.de/lbdb/"
  url "https://www.spinnaker.de/lbdb/download/lbdb-0.57.tar.gz"
  sha256 "212fe2e40df5ed3e5496bc5e821e4b0683a6c9523b8885e7e87b634bcf923a88"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://www.spinnaker.de/lbdb/download/"
    regex(/href=.*?lbdb[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a24fe81fdff56874f4b3943bac0c1d183471bcec7da31f3ab08cc511aa937617"
  end

  depends_on "abook"
  depends_on "khard"

  def install
    system "./configure", "--libexecdir=#{lib}/lbdb", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.major_minor.to_s, shell_output("#{bin}/lbdbq -v")
    assert_path_exists lib/"lbdb/m_abook", "m_abook module is missing!"
    assert_path_exists lib/"lbdb/m_khard", "m_khard module is missing!"
  end
end
