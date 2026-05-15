class WlaDx < Formula
  desc "Yet another crossassembler package"
  homepage "https://github.com/vhelin/wla-dx"
  url "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz"
  sha256 "010c4d426fd1733b978cbca7530a5e68bdfb6f62976c0d5ff7bff447894e19a8"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(/v?(\d+(?:\.\d+)+)(?:-fix)*/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5d30d0889f611771598f4a77b46fbc50fee8da581abd6c5159df5a1c1364da4d"
  end

  depends_on "cmake" => :build

  # Backport support for CMake 4
  patch do
    url "https://github.com/vhelin/wla-dx/commit/6fa1f673f010e4fa4571c40929019cd7e67d1bbd.patch?full_index=1"
    sha256 "08ba18fe27c6b0ff0bad4e9ce15a4e76be5626407e03ffdf1c19228902e02493"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test-gb-asm.s").write <<~ASM
      .MEMORYMAP
       DEFAULTSLOT 1.01
       SLOT 0.001 $0000 $2000
       SLOT 1.2 STArT $2000 sIzE $6000
       .ENDME

       .ROMBANKMAP
       BANKSTOTAL 2
       BANKSIZE $2000
       BANKS 1
       BANKSIZE $6000
       BANKS 1
       .ENDRO

       .BANK 1 SLOT 1

       .ORGA $2000


       ld hl, sp+127
       ld hl, sp-128
       add sp, -128
       add sp, 127
       adc 200
       jr -128
       jr 127
       jr nc, 127
    ASM

    system bin/"wla-gb", "-o", testpath/"test-gb-asm.s"
  end
end
