class Vcdimager < Formula
  desc "(Super) video CD authoring solution"
  homepage "https://www.gnu.org/software/vcdimager/"
  url "https://ftpmirror.gnu.org/gnu/vcdimager/vcdimager-2.0.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/vcdimager/vcdimager-2.0.1.tar.gz"
  sha256 "67515fefb9829d054beae40f3e840309be60cda7d68753cafdd526727758f67a"
  license "GPL-2.0-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "416b1dea961dae7b1a322996ac687724b0cf4336940db138e5109598b15485fb"
  end

  depends_on "pkgconf" => :build
  depends_on "libcdio"
  depends_on "popt"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"vcdimager", "--help"
  end
end
