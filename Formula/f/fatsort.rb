class Fatsort < Formula
  desc "Sorts FAT16 and FAT32 partitions"
  homepage "https://fatsort.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/fatsort/fatsort-1.7.679.tar.xz"
  sha256 "1012f551382639d69e194eabfbe99342ede7c856b1cd6788287f9dfd4bd8d122"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/fatsort[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2c6629766280652cd654930b6693ebb96bdc1b3b17c6ba084122840bd0ff2bc"
  end

  depends_on "help2man"

  def install
    system "make", "CC=#{ENV.cc}"
    bin.install "src/fatsort"
    man1.install "man/fatsort.1"
  end

  test do
    system bin/"fatsort", "--version"
  end
end
