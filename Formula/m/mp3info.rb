class Mp3info < Formula
  desc "MP3 technical info viewer and ID3 1.x tag editor"
  homepage "https://www.ibiblio.org/mp3info/"
  url "https://www.ibiblio.org/pub/linux/apps/sound/mp3-utils/mp3info/mp3info-0.8.5a.tgz"
  sha256 "0438ac68e9f04947fb14ca5573d27c62454cb9db3a93b7f1d2c226cd3e0b4e10"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.ibiblio.org/pub/linux/apps/sound/mp3-utils/mp3info/"
    regex(/href=.*?mp3info[._-]v?(\d+(?:\.\d+)+(?:[._-]?[a-z]\d*)?)\.(t|zip)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "505316b004adb1b4b9c533f9658609634391d5c50f2b57733b4910745f41a719"
  end

  uses_from_macos "ncurses"

  patch :p0 do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/mp3info/patch-mp3tech.c.diff"
    sha256 "846d6f85a3fa22908c6104436e774fc109547f7c6e9788c15dd9e602228b7892"
  end

  def install
    system "make", "mp3info", "doc"
    bin.install "mp3info"
    man1.install "mp3info.1"
  end

  test do
    system bin/"mp3info", "-x", test_fixtures("test.mp3")
  end
end
