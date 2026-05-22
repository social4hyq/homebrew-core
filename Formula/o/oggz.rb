class Oggz < Formula
  desc "Command-line tool for manipulating Ogg files"
  homepage "https://www.xiph.org/oggz/"
  url "https://ftp.osuosl.org/pub/xiph/releases/liboggz/liboggz-1.1.3.tar.gz"
  mirror "https://ftp-chi.osuosl.org/pub/xiph/releases/liboggz/liboggz-1.1.3.tar.gz"
  sha256 "2466d03b67ef0bcba0e10fb352d1a9ffd9f96911657abce3cbb6ba429c656e2f"
  license "BSD-3-Clause"

  livecheck do
    url "https://ftp.osuosl.org/pub/xiph/releases/liboggz/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)liboggz[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0f29349901884ef0e36ae5e33c509f65223f53338ccbfb682accb961da82c34"
  end

  depends_on "pkgconf" => :build
  depends_on "libogg"

  # build patch to include `<inttypes.h>` to fix missing printf format macros
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/liboggz/1.1.2-inttypes.patch"
    sha256 "0ec758ab05982dc302592f3b328a7b7c47e60672ef7da1133bcbebc4413a20a3"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"oggz", "known-codecs"
  end
end
