class Bittwist < Formula
  desc "Libcap-based Ethernet packet generator"
  homepage "https://bittwist.sourceforge.io"
  url "https://downloads.sourceforge.net/project/bittwist/macOS/Bit-Twist%204.7/bittwist-macos-4.7.tar.gz"
  sha256 "2ff00070d57221672af5198268088ffee8ed6b5ade33d6f26be5b3b4125b48f1"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7af5c71a934d70116e30bdc34c9e1a5c18be357ade0e764c4124582dfdc5451a"
  end

  uses_from_macos "libpcap"

  def install
    system "make"
    system "make", "install", "prefix=#{prefix}"
  end

  test do
    system bin/"bittwist", "-help"
    system bin/"bittwiste", "-help"
  end
end
