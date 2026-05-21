class Dopewars < Formula
  desc 'Free rewrite of a game originally based on "Drug Wars"'
  homepage "https://dopewars.sourceforge.io"
  url "https://downloads.sourceforge.net/project/dopewars/dopewars/1.6.2/dopewars-1.6.2.tar.gz"
  sha256 "623b9d1d4d576f8b1155150975308861c4ec23a78f9cc2b24913b022764eaae1"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c9e3354c74e80295924663aa5223eb1fc48416dd8e547695eb7b8097b1aa4c2"
  end

  depends_on "pkgconf" => :build

  depends_on "glib"

  uses_from_macos "curl"
  uses_from_macos "ncurses"

  on_macos do
    depends_on "gettext"
  end

  def install
    inreplace "src/Makefile.in", "$(dopewars_DEPENDENCIES)", ""
    inreplace "src/Makefile.in", "chmod", "true"
    inreplace "auxbuild/ltmain.sh", "need_relink=yes", "need_relink=no"
    inreplace "src/plugins/Makefile.in", "LIBADD =", "LIBADD = -module -avoid-version"

    system "./configure", "--disable-gui-client",
                          "--disable-gui-server",
                          "--enable-plugins",
                          "--enable-networking",
                          "--mandir=#{man}",
                          *std_configure_args
    system "make", "install", "chgrp=true"
  end

  test do
    system bin/"dopewars", "-v"
  end
end
