class Lynx < Formula
  desc "Text-based web browser"
  homepage "https://invisible-island.net/lynx/"
  url "https://invisible-mirror.net/archives/lynx/tarballs/lynx2.9.3.tar.bz2"
  mirror "https://fossies.org/linux/www/lynx2.9.3.tar.bz2"
  sha256 "174b7f2866a60f3247ba75f5c7dbb10b124aede4a1359312de15f3bfebd2050f"
  license "GPL-2.0-only" # with non-SPDX exception in COPYHEADER to use OpenSSL and other libs

  livecheck do
    url "https://invisible-mirror.net/archives/lynx/tarballs/?C=M&O=D"
    regex(/href=.*?lynx[._-]?v?(\d+(?:\.\d+)+(?:rel\.?\d+)?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6597ec13ed4ed0b6acc5a5f5bc94fe6ee88bb93bfd6a46c505a0442bc822a5de"
  end

  # Move to brew ncurses to fix screen related bugs
  depends_on "ncurses"
  depends_on "openssl@4"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    # Using --with-screen=ncurses to due to behaviour change in Big Sur
    # https://github.com/Homebrew/homebrew-core/pull/58019

    system "./configure", *std_configure_args,
                          "--mandir=#{man}",
                          "--disable-echo",
                          "--enable-default-colors",
                          "--with-zlib",
                          "--with-bzlib",
                          "--with-ssl=#{Formula["openssl@4"].opt_prefix}",
                          "--enable-ipv6",
                          "--with-screen=ncurses",
                          "--with-curses-dir=#{Formula["ncurses"].opt_prefix}",
                          "--enable-externs",
                          "--disable-config-info"
    system "make", "install"
    prefix.install "COPYHEADER"
  end

  test do
    system bin/"lynx", "-dump", "https://example.org/"
  end
end
