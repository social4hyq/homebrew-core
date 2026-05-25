class Ircii < Formula
  desc "IRC and ICB client"
  homepage "http://www.eterna23.net/ircii/"
  url "https://ircii.warped.com/ircii-20260115.tar.bz2"
  mirror "https://deb.debian.org/debian/pool/main/i/ircii/ircii_20260115.orig.tar.bz2"
  sha256 "a42749250a5eee0a57db3b72fe709bd6b8b81ec76c04c4f89f0878ef899168eb"
  license all_of: [
    "BSD-3-Clause",
    "BSD-2-Clause",
    "GPL-2.0-or-later",
    "MIT",
    :public_domain,
  ]

  livecheck do
    url "https://ircii.warped.com/"
    regex(/href=.*?ircii[._-]v?(\d{6,8})\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3be1f32cfbb48e6fd35a3067db3445cdc10fd1c86d6fff4f1e281564ff009b5c"
  end

  depends_on "openssl@3"

  uses_from_macos "libxcrypt"
  uses_from_macos "ncurses"

  def install
    ENV.append "LIBS", "-liconv" if OS.mac?
    system "./configure", "--prefix=#{prefix}",
                          "--with-default-server=irc.libera.chat",
                          "--enable-ipv6"
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    IO.popen("#{bin}/irc -d", "r+") do |pipe|
      assert_match "Connecting to port 6667 of server irc.libera.chat", pipe.gets
      pipe.puts "/quit"
      pipe.close_write
      pipe.close
    end
  end
end
