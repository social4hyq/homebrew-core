class Jnettop < Formula
  desc "View hosts/ports taking up the most network traffic"
  homepage "https://sourceforge.net/projects/jnettop/"
  url "https://downloads.sourceforge.net/project/jnettop/jnettop/0.13/jnettop-0.13.0.tar.gz"
  sha256 "a005d6fa775a85ff9ee91386e25505d8bdd93bc65033f1928327c98f5e099a62"
  license "GPL-2.0-or-later"
  revision 3

  livecheck do
    url :stable
    regex(%r{url=.*?/jnettop[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "210646bacff8f4120ebaa049f40e07b151762bde515bbc4f5692ef27df27e3f0"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"

  uses_from_macos "libpcap"
  uses_from_macos "ncurses"

  on_macos do
    depends_on "gettext"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1200

    # Fix undefined reference to `g_thread_init'
    if OS.linux?
      inreplace "Makefile.in", "$(jnettop_LDFLAGS) $(jnettop_OBJECTS)",
                               "$(jnettop_OBJECTS) $(AM_LDFLAGS) $(LDFLAGS) $(jnettop_LDFLAGS)"
    end

    system "./configure", "--man=#{man}", "--without-db4", *std_configure_args
    system "make", "install"
  end

  test do
    # need sudo access to capture packets
    assert_match version.to_s, shell_output("#{bin}/jnettop --version")
  end
end
