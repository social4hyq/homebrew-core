class X3270 < Formula
  desc "IBM 3270 terminal emulator for the X Window System and Windows"
  homepage "https://x3270.bgp.nu/"
  url "https://downloads.sourceforge.net/project/x3270/x3270/4.5ga5/suite3270-4.5ga5-src.tgz"
  sha256 "01576fa58598ccdd3d366febfaef61e3d1de93eb60a93f9ac6ba5faf84144c6f"
  license "BSD-3-Clause"

  livecheck do
    url "https://x3270.miraheze.org/wiki/Downloads"
    regex(/href=.*?suite3270[._-]v?(\d+(?:\.\d+)+(?:ga\d+)?)(?:-src)?\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de667a16f14b44ce0c7d843deda54a2d2ccdc4d40eb506f2f8efc52fc8a4fb17"
  end

  depends_on "openssl@3"
  depends_on "readline"

  uses_from_macos "python" => :build
  uses_from_macos "expat"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "bdftopcf" => :build
    depends_on "mkfontscale" => :build
    depends_on "libx11"
    depends_on "libxaw"
    depends_on "libxmu"
    depends_on "libxt"
  end

  def install
    args = %w[
      --enable-c3270
      --enable-pr3287
      --enable-s3270
    ]
    args += if OS.mac?
      %w[--disable-x3270 --enable-tcl3270]
    else
      %w[--enable-x3270 --disable-tcl3270]
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
    system "make", "install.man"
  end

  test do
    system bin/"c3270", "--version"
  end
end
