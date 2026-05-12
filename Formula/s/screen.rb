class Screen < Formula
  desc "Terminal multiplexer with VT100/ANSI terminal emulation"
  homepage "https://www.gnu.org/software/screen/"
  url "https://ftpmirror.gnu.org/gnu/screen/screen-5.0.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/screen/screen-5.0.1.tar.gz"
  sha256 "2dae36f4db379ffcd14b691596ba6ec18ac3a9e22bc47ac239789ab58409869d"
  license "GPL-3.0-or-later"
  head "https://git.savannah.gnu.org/git/screen.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d563be82779b1f2b93de9311cdf571963ab690b6b634eca7e9c7c255a116405"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libxcrypt"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "linux-pam"
  end

  def install
    args = %W[
      --mandir=#{man}
      --infodir=#{info}
      --enable-pam
    ]

    system "./autogen.sh"

    # Exclude unrecognized options
    std_args = std_configure_args.reject { |s| s["--disable-debug"] || s["--disable-dependency-tracking"] }
    system "./configure", *args, *std_args
    system "make", "install"
  end

  test do
    system bin/"screen", "-h"
  end
end
