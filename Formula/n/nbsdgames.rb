class Nbsdgames < Formula
  desc "Text-based modern games"
  homepage "https://github.com/abakh/nbsdgames"
  url "https://github.com/abakh/nbsdgames/archive/refs/tags/v6.0.2.tar.gz"
  sha256 "9545b099f6edb2be08d8885eaae2e10cf3d114c3a8fa1fc3eefff156053f37ca"
  license :public_domain
  head "https://github.com/abakh/nbsdgames.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8495794753a52826ec08680b1c6c6baa1d24f90f825eef2b5462a09ba324600e"
  end

  depends_on "findutils" => :build
  depends_on "pkgconf" => :build

  uses_from_macos "ncurses"

  def install
    mkdir bin
    system "make", "install",
           "GAMES_DIR=#{bin}",
           "SCORES_DIR=#{var}/games",
           "MAN_DIR=#{man}",
           "LIBS_PKG_CONFIG=-lncurses"

    man6.mkpath
    system "make", "manpages", "MAN_DIR=#{man6}"
  end

  test do
    assert_equal "2 <= size <= 7", shell_output("#{bin}/sudoku -s 1", 1).chomp
  end
end
