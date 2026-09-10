class Freexl < Formula
  desc "Library to extract data from Excel .xls files"
  homepage "https://www.gaia-gis.it/fossil/freexl/index"
  url "https://www.gaia-gis.it/gaia-sins/freexl-sources/freexl-2.0.0.tar.gz"
  sha256 "176705f1de58ab7c1eebbf5c6de46ab76fcd8b856508dbd28f5648f7c6e1a7f0"
  license any_of: ["MPL-1.1", "GPL-2.0-or-later", "LGPL-2.1-or-later"]
  revision 1

  livecheck do
    url :homepage
    regex(%r{current version is <b>v?(\d+(?:\.\d+)+)</b>}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "123301fb27ce337334181539a1204d030606588ed03195f9a731e045f8e9aadd"
  end

  depends_on "doxygen" => :build
  depends_on "minizip"

  uses_from_macos "expat"

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--disable-silent-rules", *args, *std_configure_args
    system "make", "install"

    system "doxygen"
    doc.install "html"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "freexl.h"

      int main()
      {
          printf("%s", freexl_version());
          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lfreexl", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end
