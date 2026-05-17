class DnscryptWrapper < Formula
  desc "Server-side proxy that adds dnscrypt support to name resolvers"
  homepage "https://cofyc.github.io/dnscrypt-wrapper/"
  url "https://github.com/cofyc/dnscrypt-wrapper/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "911856dc4e211f906ca798fcf84f5b62be7fdbf73c53e5715ce18d553814ac86"
  license "ISC"
  revision 2
  head "https://github.com/Cofyc/dnscrypt-wrapper.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5e5404d362c3f40b9c6542602f8128c13a094c326718abd977758a6775e297d"
  end

  depends_on "autoconf" => :build
  depends_on "libevent"
  depends_on "libsodium"

  def install
    # Workaround for arm64 macOS, https://github.com/cofyc/dnscrypt-wrapper/issues/177
    inreplace "compat.h", "#define HAVE_BACKTRACE 1", "" if OS.mac? && Hardware::CPU.arm?

    system "make", "configure"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system sbin/"dnscrypt-wrapper", "--gen-provider-keypair",
                                    "--provider-name=2.dnscrypt-cert.example.com",
                                    "--ext-address=192.168.1.1"
    system sbin/"dnscrypt-wrapper", "--gen-crypt-keypair"
  end
end
