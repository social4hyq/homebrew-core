class Xclip < Formula
  desc "Access X11 clipboards from the command-line"
  homepage "https://github.com/astrand/xclip"
  url "https://github.com/astrand/xclip/archive/refs/tags/0.13.tar.gz"
  sha256 "ca5b8804e3c910a66423a882d79bf3c9450b875ac8528791fb60ec9de667f758"
  license "GPL-2.0-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bdc7d86a27a9b232610c19710dd9aef6d17bcbfa8942be39206a34a0a407a0f3"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libx11"
  depends_on "libxmu"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"xclip", "-version"
  end
end
