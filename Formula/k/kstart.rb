class Kstart < Formula
  desc "Modified version of kinit that can use keytabs to authenticate"
  homepage "https://www.eyrie.org/~eagle/software/kstart/"
  url "https://archives.eyrie.org/software/kerberos/kstart-4.3.tar.xz"
  sha256 "7a3388ae79927c6698dc1bf20b29717e6bc34f692e00f12b3369d896f6702060"
  license all_of: ["MIT", "FSFAP", "ISC"]

  livecheck do
    url :homepage
    regex(/href=.*?kstart[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "29180f92c75a8e9ba04de9ba1981ca2fff60a3f27c5fb479d3ca82812d79e100"
  end

  uses_from_macos "krb5"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"k5start", "-h"
  end
end
