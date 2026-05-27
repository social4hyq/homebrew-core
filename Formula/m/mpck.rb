class Mpck < Formula
  desc "Check MP3 files for errors"
  homepage "https://checkmate.gissen.nl/"
  url "https://checkmate.gissen.nl/checkmate-0.21.tar.gz"
  sha256 "a27b4843ec06b069a46363836efda3e56e1daaf193a73a4da875e77f0945dd7a"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://checkmate.gissen.nl/download.php"
    regex(/href=.*?checkmate[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a78dd1bdb16f31a257019b98692598355bd024c4ddd11e805f06be583a085df"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"mpck", test_fixtures("test.mp3")
  end
end
