class Dromeaudio < Formula
  desc "Small C++ audio manipulation and playback library"
  homepage "https://github.com/joshb/dromeaudio/"
  url "https://github.com/joshb/DromeAudio/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "d226fa3f16d8a41aeea2d0a32178ca15519aebfa109bc6eee36669fa7f7c6b83"
  license "BSD-2-Clause"
  head "https://github.com/joshb/dromeaudio.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a04fa28690bbbc84fdfb4577f6f28f1380ff90c58acc5193c1cfca116edf6623"
  end

  deprecate! date: "2025-08-02", because: :unmaintained
  disable! date: "2026-08-02", because: :unmaintained

  depends_on "cmake" => :build

  def install
    # install FindDromeAudio.cmake under share/cmake/Modules/
    inreplace "share/CMakeLists.txt", "${CMAKE_ROOT}", "#{share}/cmake"

    # Workaround for CMake 4 compatibility
    inreplace "CMakeLists.txt", "cmake_policy(SET CMP0005 OLD)", ""
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_path_exists include/"DromeAudio"
    assert_path_exists lib/"libDromeAudio.a"

    # We don't test DromeAudioPlayer with an audio file because it only works
    # with certain audio devices and will fail on CI with this error:
    #   DromeAudio Exception: AudioDriverOSX::AudioDriverOSX():
    #   AudioUnitSetProperty (for StreamFormat) failed
    #
    # Related PR: https://github.com/Homebrew/homebrew-core/pull/55292
    assert_match(/Usage: .*?DromeAudioPlayer <filename>/i,
                 shell_output("#{bin}/DromeAudioPlayer 2>&1", 1))
  end
end
