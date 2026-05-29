class Wmctrl < Formula
  desc "UNIX/Linux command-line tool to interact with an EWMH/NetWM"
  homepage "https://packages.debian.org/sid/wmctrl"
  url "https://deb.debian.org/debian/pool/main/w/wmctrl/wmctrl_1.07.orig.tar.gz"
  sha256 "d78a1efdb62f18674298ad039c5cbdb1edb6e8e149bb3a8e3a01a4750aa3cca9"
  license "GPL-2.0-or-later"
  revision 2

  livecheck do
    url "https://deb.debian.org/debian/pool/main/w/wmctrl/"
    regex(/href=.*?wmctrl[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a4ef98fb8775d484826ea2929610ea33cf51f1eec7fd87980ed576f8b923309"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"
  depends_on "libice"
  depends_on "libsm"
  depends_on "libx11"
  depends_on "libxmu"

  on_macos do
    depends_on "gettext"
  end

  # Fix for 64-bit arch. See:
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=362068
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/wmctrl/1.07.patch"
    sha256 "8599f75e07cc45ed45384481117b0e0fa6932d1fce1cf2932bf7a7cf884979ee"
  end

  def install
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"wmctrl", "--version"
  end
end
