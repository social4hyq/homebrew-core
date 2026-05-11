class Zopfli < Formula
  desc "New zlib (gzip, deflate) compatible compressor"
  homepage "https://github.com/google/zopfli"
  url "https://github.com/google/zopfli/archive/refs/tags/zopfli-1.0.3.tar.gz"
  sha256 "e955a7739f71af37ef3349c4fa141c648e8775bceb2195be07e86f8e638814bd"
  license "Apache-2.0"
  revision 1
  head "https://github.com/google/zopfli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "164bf42fdb2134c50de5b33694a7e95c5f08a83fedffa48cd1ba708c576eda94"
  end

  deprecate! date: "2025-11-13", because: :repo_archived

  depends_on "cmake" => :build

  # Backport fix for CMake 4 compatibility
  # PR ref: https://github.com/google/zopfli/pull/207
  patch do
    url "https://github.com/google/zopfli/commit/8ef44ffde0fd2bb2a658f75887e65b31c9e44985.patch?full_index=1"
    sha256 "4a6f0b3dc53ea6de1af245231b821a94389e91eab5bd3056f5735c3de29b0402"
  end

  def install
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"zopfli"
    system bin/"zopflipng", test_fixtures("test.png"), testpath/"out.png"
    assert_path_exists testpath/"out.png"
  end
end
