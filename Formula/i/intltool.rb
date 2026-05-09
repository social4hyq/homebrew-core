class Intltool < Formula
  desc "String tool"
  homepage "https://wiki.freedesktop.org/www/Software/intltool"
  url "https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz"
  sha256 "67c74d94196b153b774ab9f89b2fa6c6ba79352407037c8c14d5aeb334e959cd"
  license "GPL-2.0-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86a25d3ad7fd8d6422abfbee12ff96bc7adb45d2f0a7324ec50b977751a1cb9b"
  end

  uses_from_macos "perl"

  on_linux do
    depends_on "perl-xml-parser"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"intltool-extract", "--help"
  end
end
