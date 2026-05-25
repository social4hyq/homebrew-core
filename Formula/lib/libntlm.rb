class Libntlm < Formula
  desc "Implements Microsoft's NTLM authentication"
  homepage "https://gitlab.com/gsasl/libntlm/"
  url "https://download.savannah.nongnu.org/releases/libntlm/libntlm-1.8.tar.gz"
  sha256 "ce6569a47a21173ba69c990965f73eb82d9a093eb871f935ab64ee13df47fda1"
  license "LGPL-2.1-or-later"

  livecheck do
    url "https://download.savannah.nongnu.org/releases/libntlm/"
    regex(/href=.*?libntlm[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb35e0215e792719ebda260d0f0406145ae69e4655c6d12029d416a0dd2682df"
  end

  def install
    system "./configure", "--disable-silent-rules",
                          *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
    pkgshare.install "config.h", "test_ntlm.c", "test.txt", "lib/md4-stream.c", "lib/md4.c", "lib/md4.h"
    pkgshare.install "lib/byteswap.h" if OS.mac?
  end

  test do
    cp pkgshare.children, testpath
    system ENV.cc, "test_ntlm.c", "md4-stream.c", "md4.c", "-I#{testpath}", "-L#{lib}", "-lntlm",
                   "-DNTLM_SRCDIR=\"#{testpath}\"", "-o", "test_ntlm"
    system "./test_ntlm"
  end
end
