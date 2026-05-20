class Sparse < Formula
  desc "Static C code analysis tool"
  homepage "https://sparse.wiki.kernel.org/"
  url "https://mirrors.edge.kernel.org/pub/software/devel/sparse/dist/sparse-0.6.4.tar.xz"
  sha256 "6ab28b4991bc6aedbd73550291360aa6ab3df41f59206a9bde9690208a6e387c"
  license "MIT"
  head "https://git.kernel.org/pub/scm/devel/sparse/sparse.git", branch: "master"

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/software/devel/sparse/dist/"
    regex(/href=.*?sparse[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71a04f58d19d8cc1da2ccd2ae88fbc9aa5a45c5056fe89f0558133c2322ed9f2"
  end

  def install
    # BSD "install" does not understand the GNU -D flag.
    # Create the parent directories ourselves.
    inreplace "Makefile", "install -D", "install"
    bin.mkpath
    man1.mkpath

    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.C").write("int main(int a) {return a;}\n")
    system bin/"sparse", testpath/"test.C"
  end
end
