class Pcapmirror < Formula
  desc "Tool for capturing network traffic on remote host using TZSP or ERSPAN"
  homepage "https://git.freestone.net/cramer/pcapmirror"
  url "https://git.freestone.net/cramer/pcapmirror/-/archive/0.6.1/pcapmirror-0.6.1.tar.gz"
  sha256 "d5efbb9b8526b8b319f3040f6a7c9532c0ca9d862b1d21100e7fc8665d0bb638"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b44d206bcd57b4dbf90081af2ef821e16c4cff28e48752a0c7c96aa55bb5dc82"
  end

  depends_on "make" => :build
  uses_from_macos "libpcap"

  on_linux do
    depends_on "libpcap"
  end

  def install
    bin.mkpath
    man8.mkpath
    system "make", "install", "BINDIR=#{bin}", "MANDIR=#{man}"
  end

  test do
    assert_match "Available network interfaces:", shell_output("#{bin}/pcapmirror -l")
  end
end
