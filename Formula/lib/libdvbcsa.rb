class Libdvbcsa < Formula
  desc "Free implementation of the DVB Common Scrambling Algorithm"
  homepage "https://www.videolan.org/developers/libdvbcsa.html"
  url "https://get.videolan.org/libdvbcsa/1.1.0/libdvbcsa-1.1.0.tar.gz"
  mirror "https://download.videolan.org/pub/videolan/libdvbcsa/1.1.0/libdvbcsa-1.1.0.tar.gz"
  sha256 "4db78af5cdb2641dfb1136fe3531960a477c9e3e3b6ba19a2754d046af3f456d"
  license "GPL-2.0-or-later"
  head "https://code.videolan.org/videolan/libdvbcsa.git", branch: "master"

  livecheck do
    url "https://get.videolan.org/libdvbcsa/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0838380757d3916b70d8048ceecb51ae87025534eaa277dcbc12bb261dcb7c4f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"

    args = std_configure_args
    args << "--enable-sse2" if Hardware::CPU.intel?
    system "./configure", *args
    system "make", "install"

    pkgshare.install "test/testbitslice.c"
  end

  test do
    # Adjust headers to allow the test to build without the upstream source tree
    cp pkgshare/"testbitslice.c", testpath/"test.c"
    inreplace "test.c",
              "#include \"dvbcsa_pv.h\"",
              "#include <stdlib.h>\n#include <stdint.h>\n#include <string.h>\n"

    system ENV.cc, testpath/"test.c", "-I#{include}", "-L#{lib}", "-ldvbcsa", "-o", "test"
    system testpath/"test"
  end
end
