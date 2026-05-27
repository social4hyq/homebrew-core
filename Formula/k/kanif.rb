class Kanif < Formula
  desc "Cluster management and administration tool"
  homepage "https://packages.debian.org/stable/net/kanif"
  url "https://deb.debian.org/debian/pool/main/k/kanif/kanif_1.2.2.orig.tar.gz"
  sha256 "3f0c549428dfe88457c1db293cfac2a22b203f872904c3abf372651ac12e5879"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://deb.debian.org/debian/pool/main/k/kanif/"
    regex(/href=.*?kanif[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc64bb2f3577d7ddfad50955aa2ac96da5586da87fcf3044dd071dae0ed6b5a6"
  end

  depends_on "taktuk"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "taktuk -s -c 'ssh' -l brew",
      shell_output("#{bin}/kash -q -l brew -r ssh")
  end
end
