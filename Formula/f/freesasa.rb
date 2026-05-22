class Freesasa < Formula
  desc "Solvent Accessible Surface Area calculations"
  homepage "https://freesasa.github.io/"
  url "https://github.com/mittinatten/freesasa/archive/refs/tags/2.1.3.tar.gz"
  sha256 "dc4fe377352569299d69329d9ded2f141e527da325960b20d2e30b5335c2b3ff"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "542c7c907aa513622a32dde0d69794980c93fb73585cc5431a6baaa13fbc3747"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build
  depends_on "json-c"

  uses_from_macos "libxml2"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
    pkgshare.install "tests/data"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/freesasa --version")

    output = shell_output("#{bin}/freesasa #{pkgshare}/data/3bkr.pdb")
    assert_match "RESULTS", output
  end
end
