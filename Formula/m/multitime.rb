class Multitime < Formula
  desc "Time command execution over multiple executions"
  homepage "https://tratt.net/laurie/src/multitime/"
  url "https://github.com/ltratt/multitime/archive/refs/tags/multitime-1.5.tar.gz"
  sha256 "4cef12f00ab0f77a2dcc1dcd2838319cdc125afe3fbf27edcc7b809388b1fa78"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "95c61e4da6e87cb63a2bd53bcc959807180a15a90e840ff79ab99d3ac51a49e9"
  end

  depends_on "autoconf" => :build

  def install
    system "autoconf"
    system "autoheader"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}"

    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/multitime -n 2 sleep 1 2>&1")
    assert_match(/((real|user|sys)\s+([01].\d{3}\s*){5}){3}/m, output)
  end
end
