class Wildmidi < Formula
  desc "Simple software midi player"
  homepage "https://github.com/Mindwerks/wildmidi"
  url "https://github.com/Mindwerks/wildmidi/archive/refs/tags/wildmidi-0.4.6.tar.gz"
  sha256 "051b8c51699af594ddd3e4e3b06bad3564e9499c3c6b9e6f880cb2f92bcfa9c8"
  license all_of: ["GPL-3.0-only", "LGPL-3.0-only"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "16ac3fb868ccb0254a8a1895fc1a8e8b73903a5cc239c4d93658ea0d2a34e8ed"
  end

  depends_on "cmake" => :build

  on_linux do
    depends_on "alsa-lib"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <wildmidi_lib.h>
      #include <stdio.h>
      #include <assert.h>
      int main() {
        long version = WildMidi_GetVersion();
        assert(version != 0);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lWildMidi"
    system "./a.out"
  end
end
