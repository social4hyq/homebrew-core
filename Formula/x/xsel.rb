class Xsel < Formula
  desc "Command-line program for getting and setting the contents of the X selection"
  homepage "https://www.vergenet.net/~conrad/software/xsel/"
  url "https://github.com/kfish/xsel/archive/refs/tags/1.2.1.tar.gz"
  sha256 "18487761f5ca626a036d65ef2db8ad9923bf61685e06e7533676c56d7d60eb14"
  license "MIT"
  revision 1
  head "https://github.com/kfish/xsel.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2003407b88464361733fa60bd0f1e225aee5f01190e4da11fd93c51e4abca078"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "libxt" => :build
  depends_on "pkgconf" => :build
  depends_on "libx11"

  def install
    system "./autogen.sh", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "Usage: xsel [options]", shell_output("#{bin}/xsel --help")
    assert_match "xsel version #{version} ", shell_output("#{bin}/xsel --version")
    assert_match "xsel: Can't open display", shell_output("DISPLAY= #{bin}/xsel -o 2>&1", 1)
  end
end
