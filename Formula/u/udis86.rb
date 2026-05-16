class Udis86 < Formula
  desc "Minimalistic disassembler library for x86"
  homepage "https://sourceforge.net/projects/udis86/"
  url "https://downloads.sourceforge.net/project/udis86/udis86/1.7/udis86-1.7.2.tar.gz"
  sha256 "9c52ac626ac6f531e1d6828feaad7e797d0f3cce1e9f34ad4e84627022b3c2f4"
  license "BSD-2-Clause"
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/udis86[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b14e64c5ecd25de1c4b84a4ae1f658ace0f78753ba154af8fc4075b58b064e6e"
  end

  depends_on "python@3.14" => :build

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--enable-shared",
                          "--with-python=#{which("python3.14")}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match("int 0x80", pipe_output("#{bin}/udcli -x", "cd 80").split.last(2).join(" "))
  end
end
