class Sparkey < Formula
  desc "Constant key-value store, best for frequent read/infrequent write uses"
  homepage "https://github.com/spotify/sparkey/"
  url "https://github.com/spotify/sparkey/archive/refs/tags/sparkey-1.0.0.tar.gz"
  sha256 "d607fb816d71d97badce6301dd56e2538ef2badb6530c0a564b1092788f8f774"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "492f281cf453689fc0637a0d99549dcd95ada52489d893701d55e1f8660f392f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "snappy"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    mv bin/"bench", bin/"sparkey_bench"
  end

  test do
    system bin/"sparkey", "createlog", "-c", "snappy", "test.spl"
    assert_empty pipe_output("#{bin}/sparkey appendlog -d . test.spl 2>&1", "foo.bar")

    system bin/"sparkey", "writehash", "test.spl"
    assert_empty shell_output("#{bin}/sparkey get test.spi foo", 2)
  end
end
