class Lightgbm < Formula
  desc "Fast, distributed, high performance gradient boosting framework"
  homepage "https://github.com/lightgbm-org/LightGBM"
  url "https://github.com/lightgbm-org/LightGBM.git",
      tag:      "v4.6.0",
      revision: "d02a01ac6f51d36c9e62388243bcb75c3b1b1774"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fbd256d1164f494c52157b7cb52cbc2afea65c5855f9f8612b46daae15f7f266"
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
