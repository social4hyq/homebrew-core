class Nudoku < Formula
  desc "Ncurses based sudoku game"
  homepage "https://jubalh.github.io/nudoku/"
  url "https://github.com/jubalh/nudoku/archive/refs/tags/8.0.1.tar.gz"
  sha256 "4e8a35950b7b7ce1e49f9457a8aceffbd21fb2b34aa8386847a7a158a2cab551"
  license "GPL-3.0-or-later"
  revision 1
  head "https://github.com/jubalh/nudoku.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9aea6a1b1d3101b480d039bdb04da7aa7960da909b7e104d39897e0b952bd977"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "pkgconf" => :build
  depends_on "cairo"

  uses_from_macos "ncurses"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules",
                          "--enable-cairo",
                          *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "nudoku version #{version}", shell_output("#{bin}/nudoku -v")
  end
end
