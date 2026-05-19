class Opencc < Formula
  desc "Simplified-traditional Chinese conversion tool"
  homepage "https://github.com/BYVoid/OpenCC"
  url "https://github.com/BYVoid/OpenCC/archive/refs/tags/ver.1.3.1.tar.gz"
  sha256 "1cc663704ff15728d6ea41ced8cd9dcc086f7bd9a80e8531b2f8054d2f3b8733"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/BYVoid/OpenCC.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f985f42a379b46632133bb20a1a4dc7416eb35e7bf54c01a26a916d57c732028"
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
