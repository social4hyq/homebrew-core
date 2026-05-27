class Greed < Formula
  desc "Game of consumption"
  homepage "http://www.catb.org/~esr/greed/"
  url "https://pkg.freebsd.org/ports-distfiles/greed-4.3.tar.gz"
  mirror "http://www.catb.org/~esr/greed/greed-4.3.tar.gz"
  sha256 "60433afaef3eb8e20e4aa33d4b5538f6ea661b1880c98cd9d7c6df86c91d4baa"
  license "BSD-2-Clause"
  head "https://gitlab.com/esr/greed.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fb0fa9af1cf0a34b182e79048439dbce29beef2ebb67734b8dc4caa01b528c47"
  end

  deprecate! date: "2024-06-07", because: :checksum_mismatch
  disable! date: "2025-06-21", because: :checksum_mismatch

  uses_from_macos "ncurses"

  def install
    # Handle hard-coded destination
    inreplace "Makefile", "/usr/share/man/man6", man6
    # Make doesn't make directories
    bin.mkpath
    man6.mkpath
    (var/"greed").mkpath
    # High scores will be stored in var/greed
    system "make", "SFILE=#{var}/greed/greed.hs"
    system "make", "install", "BIN=#{bin}"
  end

  def caveats
    <<~EOS
      High scores will be stored in the following location:
        #{var}/greed/greed.hs
    EOS
  end

  test do
    assert_predicate bin/"greed", :executable?
  end
end
