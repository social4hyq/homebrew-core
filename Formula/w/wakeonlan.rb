class Wakeonlan < Formula
  desc "Sends magic packets to wake up network-devices"
  homepage "https://github.com/jpoliv/wakeonlan"
  url "https://github.com/jpoliv/wakeonlan/archive/refs/tags/v0.50.tar.gz"
  sha256 "cbbf9d75db0cc0b8deb9d43ae0b0a320864bc6f00e032771f11a926b0aa2463f"
  license "Artistic-1.0-Perl"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aab5895cfbe743562c9b33f0a61af70ebe8f19a57ed10e77976fd4a682d14b15"
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
