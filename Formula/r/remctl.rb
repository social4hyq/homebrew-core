class Remctl < Formula
  desc "Client/server application for remote execution of tasks"
  homepage "https://www.eyrie.org/~eagle/software/remctl/"
  url "https://archives.eyrie.org/software/kerberos/remctl-3.18.tar.xz"
  sha256 "69980a0058c848f4d1117121cc9153f2daace5561d37bfdb061473f035fc35ef"
  license "MIT"

  livecheck do
    url "https://archives.eyrie.org/software/kerberos/"
    regex(/href=.*?remctl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "30615b54b0a1475d2b40ac91525b06c6ed32487d3461e5dee18069bd64d83f88"
  end

  depends_on "libevent"
  depends_on "pcre2"

  uses_from_macos "krb5"

  def install
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--with-pcre2=#{Formula["pcre2"].opt_prefix}"
    system "make", "install"
  end

  test do
    system bin/"remctl", "-v"
  end
end
