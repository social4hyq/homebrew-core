class GnupgPkcs11Scd < Formula
  desc "Enable the use of PKCS#11 tokens with GnuPG"
  homepage "https://gnupg-pkcs11.sourceforge.net/"
  url "https://github.com/alonbl/gnupg-pkcs11-scd/releases/download/gnupg-pkcs11-scd-0.11.0/gnupg-pkcs11-scd-0.11.0.tar.bz2"
  sha256 "954787e562f2b3d9294212c32dd0d81a2cd37aca250e6685002d2893bb959087"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/gnupg-pkcs11-scd[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd99d8674b9fc927394d80ab75685849419df4210ef1614046d9706f658d84c4"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "libassuan"
  depends_on "libgcrypt"
  depends_on "libgpg-error"
  depends_on "openssl@3"
  depends_on "pkcs11-helper"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    system bin/"gnupg-pkcs11-scd", "--help"
  end
end
