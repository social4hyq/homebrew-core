class Upx < Formula
  desc "Compress/expand executable files"
  homepage "https://upx.github.io/"
  url "https://github.com/upx/upx/releases/download/v5.2.1/upx-5.2.1-src.tar.xz"
  sha256 "a7d457be4ef942e46844ee8f301206b111394cbcbde3599747a6904c54ff116b"
  license "GPL-2.0-or-later"
  head "https://github.com/upx/upx.git", branch: "devel"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2b78a7df5dd62779c85c2710ab07c569e74ccc3305d8022fa3da5a92dd30591a"
  end

  depends_on "cmake" => :build
  depends_on "ucl" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"upx", "-1", "-o", "./hello", test_fixtures("elf/c.elf")
    assert_path_exists testpath/"hello"
    system bin/"upx", "-d", "./hello"
  end
end
