class Asm6809 < Formula
  desc "Cross assembler targeting the Motorola 6809 and Hitachi 6309"
  homepage "https://www.6809.org.uk/asm6809/"
  url "https://www.6809.org.uk/asm6809/dl/asm6809-2.17.tar.gz"
  sha256 "a6d36dd29cb3b26505c46595c1f0f1c4d7e66d3838f6347ce33ce27f4b35cffa"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?asm6809[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36d4b6295c3c3d850f1e267a9a5d23ea8ec253c96ce4cd37538cc5b655a738e5"
  end

  head do
    url "https://www.6809.org.uk/git/asm6809.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    input = testpath/"a.asm"

    input.write <<~ASM
      ; Instructions must be preceded by whitespace
        org $c000
        lda $42
        end $c000
    ASM

    output = testpath/"a.bin"

    system bin/"asm6809", input, "-o", output
    binary = output.binread.unpack("C*")
    assert_equal [0xb6, 0x00, 0x42], binary
  end
end
