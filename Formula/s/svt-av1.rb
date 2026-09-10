class SvtAv1 < Formula
  desc "AV1 encoder"
  homepage "https://gitlab.com/AOMediaCodec/SVT-AV1"
  url "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v4.2.0-cqp-extended/SVT-AV1-v4.2.0-cqp-extended.tar.bz2"
  version "4.2.0-cqp-extended"
  sha256 "7595ac70c08027075d48332587a1b0999f8cbb03d02d100dc053a8bd9f47d8ba"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1
  head "https://gitlab.com/AOMediaCodec/SVT-AV1.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7cff0e582e3473673501dedb2c1f64dbb9d2773766c5e880d457e03dd94a69b5"
  end

  depends_on "cmake" => :build
  depends_on "nasm" => :build

  def install
    # Features are enabled based on compiler support, and then the appropriate
    # implementations are chosen at runtime.
    # See https://gitlab.com/AOMediaCodec/SVT-AV1/-/blob/master/Source/Lib/Codec/common_dsp_rtcd.c
    ENV.runtime_cpu_detection

    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-testvideo" do
      url "https://github.com/grusell/svt-av1-homebrew-testdata/raw/main/video_64x64_yuv420p_25frames.yuv"
      sha256 "0c5cc90b079d0d9c1ded1376357d23a9782a704a83e01731f50ccd162e246492"
    end

    testpath.install resource("homebrew-testvideo")
    system bin/"SvtAv1EncApp", "-w", "64", "-h", "64", "-i", "video_64x64_yuv420p_25frames.yuv", "-b", "output.ivf"
    assert_path_exists testpath/"output.ivf"
  end
end
