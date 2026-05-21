class Mdf2iso < Formula
  desc "Tool to convert MDF (Alcohol 120% images) images to ISO images"
  homepage "https://packages.debian.org/sid/mdf2iso"
  url "https://deb.debian.org/debian/pool/main/m/mdf2iso/mdf2iso_0.3.1.orig.tar.gz"
  sha256 "906f0583cb3d36c4d862da23837eebaaaa74033c6b0b6961f2475b946a71feb7"
  license "GPL-2.0-or-later"

  livecheck do
    skip "No longer developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd8f3a6ee0cca8f90c8bb2a44fed6918999441e29f0f7a386fb2ab87a00ab611"
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mdf2iso --help")
  end
end
