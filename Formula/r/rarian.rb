class Rarian < Formula
  desc "Documentation metadata library"
  homepage "https://rarian.freedesktop.org/"
  url "https://gitlab.freedesktop.org/rarian/rarian/-/releases/0.8.6/downloads/assets/rarian-0.8.6.tar.bz2"
  sha256 "9d4f7873009d2e31b8b1ec762606b12bee5526e1fe75de48e9495382bfef2bea"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?rarian[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "565a7f8240ab07729d9080baaf04fcd846779f9181aeb2ab151aa9c9a9a1984f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "tinyxml2"

  def install
    # Regenerate `configure` to fix `-flat_namespace` bug.
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    seriesid1 = shell_output(bin/"rarian-sk-gen-uuid").strip
    sleep 5
    seriesid2 = shell_output(bin/"rarian-sk-gen-uuid").strip
    assert_match(/^\h+(?:-\h+)+$/, seriesid1)
    assert_match(/^\h+(?:-\h+)+$/, seriesid2)
    refute_equal seriesid1, seriesid2
  end
end
