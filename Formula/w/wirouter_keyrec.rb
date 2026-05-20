class WirouterKeyrec < Formula
  desc "Recover the default WPA passphrases from supported routers"
  homepage "https://www.salvatorefresta.net/tools/"
  url "https://www.mirrorservice.org/sites/distfiles.macports.org/wirouterkeyrec/WiRouter_KeyRec_1.1.2.zip"
  mirror "https://distfiles.macports.org/wirouterkeyrec/WiRouter_KeyRec_1.1.2.zip"
  sha256 "3e59138f35502b32b47bd91fe18c0c232921c08d32525a2ae3c14daec09058d4"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(%r{href=.*?/WiRouter_KeyRec[._-]v?(\d+(?:\.\d+)+)\.zip}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c95e84e6624dcb58052d4128b45d4f2e183a71411090bdabc8e453468224d36b"
  end

  def install
    inreplace "src/agpf.h", %r{/etc}, "#{prefix}/etc"
    inreplace "src/teletu.h", %r{/etc}, "#{prefix}/etc"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{prefix}",
                          "--exec-prefix=#{prefix}"
    system "make", "prefix=#{prefix}"
    system "make", "install", "DESTDIR=#{prefix}", "BIN_DIR=bin/"
  end

  test do
    system bin/"wirouterkeyrec", "-s", "Alice-12345678"
  end
end
