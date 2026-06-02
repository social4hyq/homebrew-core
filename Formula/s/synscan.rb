class Synscan < Formula
  desc "Asynchronous half-open TCP portscanner"
  homepage "https://digit-labs.org/files/tools/synscan/"
  url "https://digit-labs.org/files/tools/synscan/releases/synscan-5.02.tar.gz"
  sha256 "c4e6bbcc6a7a9f1ea66f6d3540e605a79e38080530886a50186eaa848c26591e"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?synscan[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca0683d6e872215675a180570dfd491b55d1958909236889868b8c4be7aae205"
  end

  depends_on "libpcap"

  def install
    # Ideally we pass the prefix into --with-libpcap, but that option only checks "flat"
    # i.e. it only works if the headers and libraries are in the same directory.
    ENV.append_to_cflags "-I#{Formula["libpcap"].opt_include}"
    ENV.append "LIBS", "-L#{Formula["libpcap"].opt_lib} -lpcap"
    system "./configure", "--prefix=#{prefix}",
                          "--with-libpcap=yes"

    target = OS.mac? ? "macos" : OS.kernel_name.downcase
    system "make", target
    system "make", "install"
  end

  test do
    system bin/"synscan", "-V"
  end
end
