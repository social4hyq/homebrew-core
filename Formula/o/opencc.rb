class Opencc < Formula
  desc "Simplified-traditional Chinese conversion tool"
  homepage "https://github.com/BYVoid/OpenCC"
  url "https://github.com/BYVoid/OpenCC/archive/refs/tags/ver.1.4.1.tar.gz"
  sha256 "d4b94877c508a4774853f3b07330b3d25df00105c39dfba6ab9889d77946cc8a"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/BYVoid/OpenCC.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38f7ff9c0f89053f1961dd16ff55f3894893fe9d25500ffe12829d5ae1d7277e"
  end

  depends_on "cmake" => :build
  depends_on "marisa"
  uses_from_macos "python" => :build

  def install
    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DPYTHON_EXECUTABLE=#{which("python3")}
      -DUSE_SYSTEM_MARISA=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    input = "中国鼠标软件打印机"
    output = pipe_output(bin/"opencc", input)
    output = output.force_encoding("UTF-8") if output.respond_to?(:force_encoding)
    assert_match "中國鼠標軟件打印機", output
  end
end
