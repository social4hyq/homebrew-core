class Sng < Formula
  desc "Enable lossless editing of PNGs via a textual representation"
  homepage "https://sng.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/sng/sng-1.1.1.tar.xz"
  sha256 "c9bdfb80f5a17db1aab9337baed64a8ebea5c0ddf82915c6887b8cfb87ece61e"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d395e9b483eecd007c9ac70dd31ff4971dab2f75a76c2febd50e413f40b93340"
  end

  depends_on "libpng"
  depends_on "xorgrgb"

  def install
    # Fix RGBTXT ref to use Homebrew share path
    inreplace "Makefile", "/usr/share/X11/rgb.txt", "#{HOMEBREW_PREFIX}/share/X11/rgb.txt"

    system "make", "install", "DESTDIR=#{prefix}", "prefix=/", "CC=#{ENV.cc}"
  end

  test do
    cp test_fixtures("test.png"), "test.png"
    system bin/"sng", "test.png"
    assert_includes File.read("test.sng"), "width: 8; height: 8; bitdepth: 8;"
  end
end
