class Uftp < Formula
  desc "Secure, reliable, efficient multicast file transfer program"
  homepage "https://uftp-multicast.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/uftp-multicast/source-tar/uftp-5.0.3.tar.gz"
  sha256 "cb8668c19b1f10bc63a16ffa893e205dc3ec86361037d477d8003260ebc40080"
  license "GPL-3.0-or-later" => { with: "openvpn-openssl-exception" }
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/uftp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ea092a1892d53c229f647109c2ef7657a6bcd090e33ec8ebf632ab86db9b4ccf"
  end

  depends_on "openssl@4"

  def install
    system "make", "OPENSSL=#{Formula["openssl@4"].opt_prefix}", "DESTDIR=#{prefix}", "install"
    # the makefile installs into DESTDIR/usr/..., move everything up one and remove usr
    # the project maintainer was contacted via sourceforge on 12-Feb, he responded WONTFIX on 13-Feb
    prefix.install (prefix/"usr").children
    (prefix/"usr").unlink
  end

  service do
    run [opt_bin/"uftpd", "-d"]
    keep_alive true
    working_dir var
  end

  test do
    system bin/"uftp_keymgt"
  end
end
