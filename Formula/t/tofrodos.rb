class Tofrodos < Formula
  desc "Converts DOS <-> UNIX text files, alias tofromdos"
  homepage "https://github.com/ChristopherHeng/tofrodos"
  url "https://github.com/ChristopherHeng/tofrodos/archive/refs/tags/2.1.1.tar.gz"
  sha256 "77e6855917e5dd04ff445b6de3f8373531af15b2cb70e3b29058658f9d495c06"
  license "GPL-2.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "540a2b10e7f48bef0f0f4c067cac6b7b1997f99f04f0b99fbe2d85fa42812ef2"
  end

  def install
    mkdir_p [bin, man1]

    system "make", "-f", "makefile.gcc", "all"
    system "make", "-f", "makefile.gcc", "BINDIR=#{bin}", "MANDIR=#{man1}", "install"
  end

  test do
    (testpath/"test.txt").write <<~EOS
      Example text
    EOS

    shell_output("#{bin}/todos -b #{testpath}/test.txt")
    shell_output("#{bin}/fromdos #{testpath}/test.txt")
    assert_equal (testpath/"test.txt").read, (testpath/"test.txt.bak").read
  end
end
