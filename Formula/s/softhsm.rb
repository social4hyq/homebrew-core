class Softhsm < Formula
  desc "Cryptographic store accessible through a PKCS#11 interface"
  homepage "https://www.softhsm.org/"
  url "https://github.com/softhsm/SoftHSMv2/archive/refs/tags/2.7.0.tar.gz"
  sha256 "be14a5820ec457eac5154462ffae51ba5d8a643f6760514d4b4b83a77be91573"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/opendnssec/SoftHSMv2.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61d0158c75c2bcc413277f1207d767ac6cb1b936353a08332b1e6da184cfddf7"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-silent-rules",
                          "--localstatedir=#{var}",
                          "--sysconfdir=#{pkgetc}",
                          "--with-crypto-backend=openssl",
                          "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          "--disable-gost",
                          *std_configure_args
    system "make", "install"

    (var/"lib/softhsm/tokens").mkpath
  end

  test do
    (testpath/"softhsm2.conf").write("directories.tokendir = #{testpath}")
    ENV["SOFTHSM2_CONF"] = testpath/"softhsm2.conf"
    system bin/"softhsm2-util", "--init-token", "--slot", "0",
                                "--label", "testing", "--so-pin", "1234",
                                "--pin", "1234"
    system bin/"softhsm2-util", "--show-slots"
  end
end
