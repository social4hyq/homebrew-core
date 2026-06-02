class Yafc < Formula
  desc "Command-line FTP client"
  homepage "https://github.com/sebastinas/yafc"
  url "https://deb.debian.org/debian/pool/main/y/yafc/yafc_1.3.7.orig.tar.xz"
  sha256 "4b3ebf62423f21bdaa2449b66d15e8d0bb04215472cb63a31d473c3c3912c1e0"
  license "GPL-2.0-or-later"
  revision 5

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4e3a06cb7df8d23be7c54db357c0f3324046daeee1d7b67d0fc7abf9dab6eb12"
  end

  depends_on "pkgconf" => :build
  depends_on "libssh"
  depends_on "openssl@3"
  depends_on "readline"

  on_linux do
    depends_on "libbsd"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --with-readline=#{Formula["readline"].opt_prefix}
    ]

    system "./configure", *args
    system "make", "install"
  end

  test do
    ftp_url = "ftp://ftp.mirrorservice.org/sites/ftp.gnu.org/gnu/gcc/gcc-10.2.0/"
    download_file = testpath/"gcc-10.2.0.tar.xz.sig"
    expected_checksum = Checksum.new("8e271266e0e3312bb1c384c48b01374e9c97305df781599760944e0a093fad38")
    output = pipe_output("#{bin}/yafc -W #{testpath} -a #{ftp_url}", "get #{download_file.basename}", 0)
    assert_match version.to_s, output
    download_file.verify_checksum expected_checksum
  end
end
