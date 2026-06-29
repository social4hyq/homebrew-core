class Xdelta < Formula
  desc "Binary diff, differential compression tools"
  homepage "https://github.com/jmacd/xdelta"
  url "https://github.com/jmacd/xdelta/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "ba2c9676b325f1958e504a60a20340145b8073d5f8664092de17389e15a93199"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "896ac3a4e92012534fa732cf0a1cd7350b138a3353860e0fd9389571bfe3237e"
  end

  depends_on "cmake" => :build
  depends_on "blake3"
  depends_on "xz"

  def install
    # Fix library target to the same as `blake3` formula.
    inreplace "xdelta3/CMakeLists.txt",
              "set(XD3_ARMOR_LIBRARIES blake3)",
              "set(XD3_ARMOR_LIBRARIES BLAKE3::blake3)"

    args = %w[
      -DXD3_BUILD_TESTS=OFF
      -DXD3_LZMA_MODE=on
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON
      -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=ALWAYS
    ]
    system "cmake", "-S", "xdelta3", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"xdelta3", "config"
  end
end
