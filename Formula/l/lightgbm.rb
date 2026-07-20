class Lightgbm < Formula
  desc "Fast, distributed, high performance gradient boosting framework"
  homepage "https://github.com/lightgbm-org/LightGBM"
  url "https://github.com/lightgbm-org/LightGBM.git",
      tag:      "v4.7.0",
      revision: "8f7036f03627054d5a54a6f965b13f4b9ff2cb63"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9563d41216dd4d3904643539d050c98ea502c77d71f6c2dbb086d01c75f65411"
  end

  depends_on "cmake" => :build

  on_macos do
    depends_on "libomp"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "examples"
  end

  test do
    cp_r (pkgshare/"examples/regression"), testpath
    cd "regression" do
      system bin/"lightgbm", "config=train.conf"
    end
  end
end
