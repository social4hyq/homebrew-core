class Udptunnel < Formula
  desc "Tunnel UDP packets over a TCP connection"
  # The original webpage (and download) is still available at the original
  # site, but currently www.cs.columbia.edu returns a 404 error if you
  # try to fetch them over https instead of http
  homepage "http://www1.cs.columbia.edu/~lennox/udptunnel/"
  url "https://pkg.freebsd.org/ports-distfiles/udptunnel-1.1.tar.gz"
  mirror "https://sources.voidlinux.org/udptunnel-1.1/udptunnel-1.1.tar.gz"
  sha256 "45c0e12045735bc55734076ebbdc7622c746d1fe4e6f7267fa122e2421754670"
  license "BSD-3-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?udptunnel[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58cc16fe1a2c30c763b9b8fb195fc753bbf64541cba07d5cab8971222aa1ad2b"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  on_linux do
    depends_on "libnsl"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1200

    ENV["LIBS"] = "-L#{Formula["libnsl"].opt_lib}" if OS.linux?

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    doc.install "udptunnel.html"
  end

  test do
    assert_equal <<~EOS, shell_output("#{bin}/udptunnel -h 2>&1", 2)
      Usage: #{bin}/udptunnel -s TCP-port [-r] [-v] UDP-addr/UDP-port[/ttl]
          or #{bin}/udptunnel -c TCP-addr[/TCP-port] [-r] [-v] UDP-addr/UDP-port[/ttl]
           -s: Server mode.  Wait for TCP connections on the port.
           -c: Client mode.  Connect to the given address.
           -r: RTP mode.  Connect/listen on ports N and N+1 for both UDP and TCP.
               Port numbers must be even.
           -v: Verbose mode.  Specify -v multiple times for increased verbosity.
    EOS
  end
end
