class Vc4asm < Formula
  desc "Macro assembler for Broadcom VideoCore IV aka Raspberry Pi GPU"
  homepage "https://maazl.de/project/vc4asm/doc/index.html"
  url "https://github.com/maazl/vc4asm/archive/refs/tags/V0.3.tar.gz"
  sha256 "f712fb27eb1b7d46b75db298fd50bb62905ccbdd7c0c7d27728596c496f031c2"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e83a81c4ec0c3da25240d7a58f30d8f615dda4aa0ab63846d28e5e40e7d727a3"
  end

  depends_on "cmake" => :build

  # Backport fix for GCC 9+
  patch do
    url "https://github.com/maazl/vc4asm/commit/ff16f635b07e14b07c1de69bf322e3bf7feecd93.patch?full_index=1"
    sha256 "b4c6e87018aa512ff8398cc77bd3f80dd9aaca196c3da76a845db7e25eaac99b"
  end

  def install
    # Upstream create a "CMakeCache.txt" directory in their tarball
    # because they don't want CMake to write a cache file, but brew
    # expects this to be a file that can be copied to HOMEBREW_LOGS
    rm_r "CMakeCache.txt"

    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.qasm").write <<~ASM
      mov -, sacq(9)
      add r0, r4, ra1.unpack8b
      add.unpack8ai r0, r4, ra1
      add r0, r4.8a, ra1
    ASM
    system bin/"vc4asm", "-o test.hex", "-V", "#{share}/vc4inc/vc4.qinc", "test.qasm"
  end
end
