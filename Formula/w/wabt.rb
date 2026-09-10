class Wabt < Formula
  desc "Web Assembly Binary Toolkit"
  homepage "https://github.com/WebAssembly/wabt"
  url "https://github.com/WebAssembly/wabt/releases/download/1.0.41/wabt-1.0.41.tar.xz"
  sha256 "ca9e69cc1de13b4633a3c74fd697319303b21108529d4f10960af4e1f4a65893"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c04dc44608ba67a2c22bc98c78eb917459ff14cc1bdcf0ce5cd7f61d0283b715"
  end

  depends_on "cmake" => :build
  depends_on "openssl@3"

  uses_from_macos "python" => :build

  def install
    args = %w[
      -DBUILD_TESTS=OFF
      -DWITH_WASI=ON
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"sample.wast").write("(module (memory 1) (func))")
    system bin/"wat2wasm", testpath/"sample.wast"
  end
end
