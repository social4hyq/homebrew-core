class DevelBase < Formula
  desc "Essential build tools collection"
  homepage "https://gitcode.com/Harmonybrew/homebrew-core"
  url "https://gitcode.com/Harmonybrew/homebrew-core.git", revision: "a8784ea451ad819d27a548411b8853fca6de3124"
  version "1.0.0"
  license "BSD-2-Clause"

  depends_on "coreutils"
  depends_on "diffutils"
  depends_on "gawk"
  depends_on "gnu-tar"
  depends_on "gpatch"
  depends_on "grep"
  depends_on "gzip"

  depends_on "llvm-gcc-compat"

  depends_on "make"
  depends_on "texinfo"

  def install
    (pkgshare/"meta.txt").write "This formula only pulls in dependencies."
  end

  test do
    system "true"
  end
end
