class Shmux < Formula
  desc "Execute the same command on many hosts in parallel"
  homepage "https://github.com/shmux/shmux"
  url "https://github.com/shmux/shmux/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "c9f8863e2550e23e633cf5fc7a9c4c52d287059f424ef78aba6ecd98390fb9ab"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1da3e07f60fe516cce7a27f179da9d9596a63051b8377710e27ff24508de1e9"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"shmux", "-h"
  end
end
