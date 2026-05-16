class Uvg266 < Formula
  desc "Open-source VVC/H.266 encoder"
  homepage "https://github.com/ultravideo/uvg266"
  url "https://github.com/ultravideo/uvg266/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "9a2c68f94a1105058d1e654191036423d0a0fcf33b7e790dd63801997540b6ec"
  license "BSD-3-Clause"
  head "https://github.com/ultravideo/uvg266.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "405abe6adfda0796b9d59c27d12b5c3f8ec403ef6a5c16092477454c20d6a9ad"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-videosample" do
      url "https://samples.mplayerhq.hu/V-codecs/lm20.avi"
      sha256 "a0ab512c66d276fd3932aacdd6073f9734c7e246c8747c48bf5d9dd34ac8b392"
    end
    testpath.install resource("homebrew-videosample")

    system bin/"uvg266", "-i", "lm20.avi", "--input-res", "16x16", "-o", "lm20.vvc"
    assert_path_exists testpath/"lm20.vvc"
  end
end
