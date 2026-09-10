class DevelBase < Formula
  desc "Essential build tools collection"
  homepage "https://atomgit.com/Harmonybrew/homebrew-core"
  url "https://atomgit.com/Harmonybrew/homebrew-core.git", revision: "a8784ea451ad819d27a548411b8853fca6de3124"
  version "1.0.1"
  license "BSD-2-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "357fb37802bfafda1bf719168301f3a8213ae531b024678e7e48d0e191e3dbea"
  end

  depends_on "coreutils"
  depends_on "diffutils"
  depends_on "gawk"
  depends_on "gnu-sed"
  depends_on "gnu-tar"
  depends_on "gpatch"
  depends_on "grep"
  depends_on "gzip"
  depends_on "llvm-gcc-compat"
  depends_on "make"
  depends_on "ohos-sdk"
  depends_on "texinfo"

  def install
    (pkgshare/"meta.txt").write "This formula only pulls in dependencies."
  end

  test do
    system "true"
  end
end
