class Vvdec < Formula
  desc "Fraunhofer Versatile Video Decoder"
  homepage "https://www.hhi.fraunhofer.de/en/departments/vca/technologies-and-solutions/h266-vvc.html"
  url "https://github.com/fraunhoferhhi/vvdec/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "fb722da3c4d0a562969fd9540c67239e6265ae1e664ce563ad586e78ef4adb3b"
  license "BSD-3-Clause-Clear"
  head "https://github.com/fraunhoferhhi/vvdec.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3779c16dc3086424233cc528bf0ac9ac51f6ffb2b2537b0b11ddc8d2547ee157"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DBUILD_SHARED_LIBS=1",
           "-DVVDEC_INSTALL_VVDECAPP=1",
           "-DVVDEC_ENABLE_ARM_SIMD_RDM=OFF",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-test-video" do
      url "https://archive.org/download/testvideo_20230410_202304/test.vvc"
      sha256 "753261009b6472758cde0dee2c004ff712823b43e62ec3734f0f46380bec8e46"
    end

    resource("homebrew-test-video").stage testpath
    system bin/"vvdecapp", "-b", testpath/"test.vvc", "-o", testpath/"test.yuv"
    assert_path_exists testpath/"test.yuv"
  end
end
