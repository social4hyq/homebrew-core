class Ngrep < Formula
  desc "Network grep"
  homepage "https://github.com/jpr5/ngrep"
  url "https://github.com/jpr5/ngrep/archive/refs/tags/v1.49.0.tar.gz"
  sha256 "6c94b31681316b7469a3ace92d2aeec7c9f490bd6782453dff2ade0e289a3348"
  license "ngrep"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "613da36053bc274ac1a9c183c989256b0384a03f98e6112a17c2a541e4d10471"
  end

  depends_on "libpcap"
  depends_on "pcre2"

  def install
    args = %w[
      --enable-ipv6
      --enable-pcre2
    ]
    args << "--with-pcap-includes=#{Formula["libpcap"].opt_include}"

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ngrep -V")
  end
end
