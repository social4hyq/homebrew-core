class Sl < Formula
  desc "Prints a steam locomotive if you type sl instead of ls"
  homepage "https://github.com/mtoyoda/sl"
  url "https://github.com/mtoyoda/sl/archive/refs/tags/5.02.tar.gz"
  sha256 "1e5996757f879c81f202a18ad8e982195cf51c41727d3fea4af01fdcbbb5563a"
  license "MIT"
  head "https://github.com/mtoyoda/sl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e7a997a79660b017be7a2956c5addb19c7ff4176daf36a82b271476aab1bbab"
  end

  uses_from_macos "ncurses"

  conflicts_with "sapling", because: "both install `sl` binaries"

  def install
    system "make", "-e"
    bin.install "sl"
    man1.install "sl.1"
  end

  test do
    system bin/"sl", "-c"
  end
end
