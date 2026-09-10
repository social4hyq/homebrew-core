class Leveldb < Formula
  desc "Key-value storage library with ordered mapping"
  homepage "https://github.com/google/leveldb/"
  url "https://github.com/google/leveldb/archive/refs/tags/1.23.tar.gz"
  sha256 "9a37f8a6174f09bd622bc723b55881dc541cd50747cbd08831c2a82d620f6d76"
  license "BSD-3-Clause"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bd6710313c40b90c201f08e02701c50b6ab06f45b46c318742e0cb7b3aa63ed7"
  end

  depends_on "cmake" => :build
  depends_on "snappy"

  def install
    args = %W[
      -DLEVELDB_BUILD_TESTS=OFF
      -DLEVELDB_BUILD_BENCHMARKS=OFF
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build_shared",
                      *args, "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
    bin.install "build_shared/leveldbutil"

    system "cmake", "-S", ".", "-B", "build_static",
                      *args, "-DBUILD_SHARED_LIBS=OFF", *std_cmake_args
    system "cmake", "--build", "build_static"
    lib.install "build_static/libleveldb.a"
  end

  test do
    assert_match "dump files", shell_output("#{bin}/leveldbutil 2>&1", 1)
  end
end
