class Gdbm < Formula
  desc "GNU database manager"
  homepage "https://www.gnu.org.ua/software/gdbm/"
  url "https://ftpmirror.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz"
  sha256 "6a24504a14de4a744103dcb936be976df6fbe88ccff26065e54c1c47946f4a5e"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f7ece69bf2a1830d8e6159b2aa7850fa1a26e736d7cdd01c7d7fe0ab5a4939f4"
  end

  def install
    # --enable-libgdbm-compat for dbm.h / gdbm-ndbm.h compatibility:
    #   https://www.gnu.org.ua/software/gdbm/manual/html_chapter/gdbm_19.html
    # Use --without-readline because readline detection is broken in 1.13
    # https://github.com/Homebrew/homebrew-core/pull/10903
    args = %w[
      --disable-silent-rules
      --enable-libgdbm-compat
      --without-readline
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"

    # Avoid conflicting with macOS SDK's ndbm.h.  Renaming to gdbm-ndbm.h
    # matches Debian's convention for gdbm's ndbm.h (libgdbm-compat-dev).
    mv include/"ndbm.h", include/"gdbm-ndbm.h"
  end

  test do
    pipe_output("#{bin}/gdbmtool --norc --newdb test", "store 1 2\nquit\n")
    assert_path_exists testpath/"test"
    assert_match "2", pipe_output("#{bin}/gdbmtool --norc test", "fetch 1\nquit\n")
  end
end
