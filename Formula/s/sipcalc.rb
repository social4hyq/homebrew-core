class Sipcalc < Formula
  desc "Advanced console-based IP subnet calculator"
  homepage "https://www.routemeister.net/projects/sipcalc/"
  url "https://www.routemeister.net/projects/sipcalc/files/sipcalc-1.1.6.tar.gz"
  sha256 "cfd476c667f7a119e49eb5fe8adcfb9d2339bc2e0d4d01a1d64b7c229be56357"
  license "BSD-3-Clause"

  livecheck do
    url "https://www.routemeister.net/projects/sipcalc/download.html"
    regex(/href=.*?sipcalc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9a4c25812d9d60d7bb152e1b9a7d85c59af3868c70f99bfd0403a38f7607148c"
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"sipcalc", "-h"
  end
end
