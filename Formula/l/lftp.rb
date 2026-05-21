class Lftp < Formula
  desc "Sophisticated file transfer program"
  homepage "https://lftp.yar.ru/"
  url "https://github.com/lavv17/lftp/releases/download/v4.9.3/lftp-4.9.3.tar.gz"
  sha256 "68116cc184ab660a78a4cef323491e89909e5643b59c7b5f0a14f7c2b20e0a29"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8712f419b0c5828bd6913a056b6481209f5933651713055bbb421ab1a088d90d"
  end

  depends_on "libidn2"
  depends_on "openssl@3"
  depends_on "readline"

  uses_from_macos "ncurses"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Fix compile with newer Clang
    # https://github.com/lavv17/lftp/issues/611
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1200

    system "./configure", "--disable-silent-rules",
                          "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          "--with-readline=#{Formula["readline"].opt_prefix}",
                          "--with-libidn2=#{Formula["libidn2"].opt_prefix}",
                          *std_configure_args

    system "make", "install"
  end

  test do
    system bin/"lftp", "-c", "open https://ftpmirror.gnu.org/; ls"
  end
end
