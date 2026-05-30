class Libsoundio < Formula
  desc "Cross-platform audio input and output"
  homepage "http://libsound.io"
  url "https://github.com/andrewrk/libsoundio/archive/refs/tags/2.0.1-7.tar.gz"
  sha256 "941f1347dabab02c88ef57e225b04587c3f69824e550e1045e4a9119cd657a4e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ab332a451381dc664656fa070d6d0cbc80dfc6aab4c103888dda9ccb335e620"
  end

  depends_on "cmake" => :build

  def install
    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <soundio/soundio.h>

      int main() {
        struct SoundIo *soundio = soundio_create();

        if (!soundio) { return 1; }
        if (soundio_connect(soundio)) return 1;

        soundio_flush_events(soundio);
        soundio_destroy(soundio);

        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lsoundio", "-o", "test"
    system "./test"
  end
end
