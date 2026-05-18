class Vvdec < Formula
  desc "Fraunhofer Versatile Video Decoder"
  homepage "https://github.com/fraunhoferhhi/vvdec"
  url "https://github.com/fraunhoferhhi/vvdec/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "e3e5093acfdcbfd2159f3d0166d451d7ccabd293ed30f3762b481c9c6c0a7512"
  license "BSD-3-Clause-Clear"
  head "https://github.com/fraunhoferhhi/vvdec.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b36265c2ecedbb224943213745be11406df2fdf4f28844ef3c10fcceefb9645"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DBUILD_SHARED_LIBS=1",
           "-DVVDEC_INSTALL_VVDECAPP=1",
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
