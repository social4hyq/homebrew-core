class Pciutils < Formula
  desc "PCI utilities"
  homepage "https://github.com/pciutils/pciutils"
  url "https://github.com/pciutils/pciutils/archive/refs/tags/v3.15.0.tar.gz"
  sha256 "06f467642057599acf396bc17340452fac3308f1e08be19e0c32587e42d7017b"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "99706f92d052abe2758fea82822b22dff02ba4edcaf64e3d06a04b56e509c6a9"
  end

  depends_on :linux # arm64 macOS is not supported: https://github.com/pciutils/pciutils/issues/111
  depends_on "zlib-ng-compat"

  def install
    args = ["ZLIB=yes", "DNS=yes", "SHARED=yes", "PREFIX=#{prefix}", "MANDIR=#{man}"]
    system "make", *args
    system "make", "install", *args
    system "make", "install-lib", *args
  end

  test do
    assert_match "lspci version", shell_output("#{bin}/lspci --version")
    assert_match(/Host bridge:|controller:/, shell_output("#{bin}/lspci"))
  end
end
