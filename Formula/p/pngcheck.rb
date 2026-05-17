class Pngcheck < Formula
  desc "Print info and check PNG, JNG, and MNG files"
  homepage "https://github.com/pnggroup/pngcheck"
  url "https://github.com/pnggroup/pngcheck/archive/refs/tags/v4.0.1.tar.gz"
  sha256 "a24ac2348efca5895e9d6f53fd316f3d5c409ab92a74b2b8106541759304da53"
  license "HPND"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b75106a3b2ed8394b0dd2be1caf33509fe1cd59de26288ad75bcee90e4eafaa8"
  end

  depends_on "cmake" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Remove files only needed on non-Unix. Doesn't need to be removed as CMake handles it
    # but they have different or dubious licenses so let's be explicit to prove that the above license DSL is correct.
    rm_r "amiga"
    rm_r "third_party"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"pngcheck", test_fixtures("test.png")
  end
end
