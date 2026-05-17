class GnuGo < Formula
  desc "Plays the game of Go"
  homepage "https://www.gnu.org/software/gnugo/gnugo.html"
  url "https://ftpmirror.gnu.org/gnu/gnugo/gnugo-3.8.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gnugo/gnugo-3.8.tar.gz"
  sha256 "da68d7a65f44dcf6ce6e4e630b6f6dd9897249d34425920bfdd4e07ff1866a72"
  # The `:cannot_represent` is for src/gtp.* which is similar to ICU license if
  # SPDX allowed replacing `this software ... (the "Software")` with `file gtp.c`
  license all_of: ["GPL-3.0-or-later", :public_domain, :cannot_represent]
  revision 1
  head "https://git.savannah.gnu.org/git/gnugo.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "351eaa067a56801c42044cbbe87400727cf0707731102f7389de52d5f221545d"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `DRAW'; globals.o:(.bss+0x0): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", "--with-readline", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match(/GNU Go #{version}$/, shell_output("#{bin}/gnugo --version"))
  end
end
