class Mhash < Formula
  desc "Uniform interface to a large number of hash algorithms"
  homepage "https://mhash.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz"
  sha256 "3dcad09a63b6f1f634e64168dd398e9feb9925560f9b671ce52283a79604d13e"
  license all_of: ["LGPL-2.0-or-later", "LGPL-2.1-or-later", "GPL-2.0-or-later"]

  livecheck do
    url :stable
    regex(%r{url=.*?/mhash[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d1bc5aae32725c2ea08a5b4af42a172d7e1a69b3a9c7716079ddc3379d57dbeb"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    # Regenerate the very old configure script that isn't suitable for modern macOS.
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "mhash.h"
      int main() {
        MHASH td;
        return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-L#{lib}", "-lmhash", "-o", "test"
    system "./test"
  end
end
