class Debianutils < Formula
  desc "Miscellaneous utilities specific to Debian"
  homepage "https://tracker.debian.org/pkg/debianutils"
  url "https://deb.debian.org/debian/pool/main/d/debianutils/debianutils_5.24.tar.xz"
  sha256 "bf79c301ad48e82ddb09d8c0770f6d44294ee9529ae5e54164072f7bf5c57016"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?debianutils[._-]v?(\d+(?:\.\d+)+).dsc/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e745db11305ce7c5265c72562f37927068e336d00bb2cdb642bf6d261b7fc935"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build # for libintl
  depends_on "libtool" => :build
  depends_on "po4a" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make"

    # Some commands are Debian Linux specific and we don't want them, so install specific tools
    bin.install "run-parts", "ischroot", "tempfile"
    man1.install "ischroot.1", "tempfile.1"
    man8.install "run-parts.8"
  end

  test do
    output = shell_output("#{bin}/tempfile -d #{Dir.pwd}").strip
    assert_path_exists Pathname.new(output)
  end
end
