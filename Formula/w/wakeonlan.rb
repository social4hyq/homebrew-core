class Wakeonlan < Formula
  desc "Sends magic packets to wake up network-devices"
  homepage "https://github.com/jpoliv/wakeonlan"
  url "https://github.com/jpoliv/wakeonlan/archive/refs/tags/v0.50.tar.gz"
  sha256 "cbbf9d75db0cc0b8deb9d43ae0b0a320864bc6f00e032771f11a926b0aa2463f"
  license "Artistic-1.0-Perl"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58dcd3f02a2f7b3ebdf440b625fbaac455f80519dbcb5e1d2981a1a22f058616"
  end

  # Build with Homebrew `perl` to build an `:all` bottle.
  depends_on "perl" => :build
  uses_from_macos "perl"

  def install
    system "perl", "Makefile.PL"
    system "make"
    bin.install "blib/script/wakeonlan"
    man1.install "blib/man1/wakeonlan.1"
  end

  test do
    system bin/"wakeonlan", "--version"
  end
end
