class Sqlitecpp < Formula
  desc "Smart and easy to use C++ SQLite3 wrapper"
  homepage "https://srombauts.github.io/SQLiteCpp/"
  url "https://github.com/SRombauts/SQLiteCpp/archive/refs/tags/3.3.3.tar.gz"
  sha256 "33bd4372d83bc43117928ee842be64d05e7807f511b5195f85d30015cad9cac6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8ce5badc5aac30317be2f10d3c62b15a8d16a69858b8511f5951423dbe1863b1"
  end

  depends_on "cmake" => :build
  depends_on "sqlite" # needs sqlite3_load_extension

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DSQLITECPP_INTERNAL_SQLITE=OFF",
                    "-DSQLITECPP_RUN_CPPLINT=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (pkgshare/"example").install "examples/example2/src/main.cpp"
  end

  test do
    system ENV.cxx, "-std=c++11", pkgshare/"example/main.cpp", "-o", "test", "-L#{lib}", "-lSQLiteCpp"
    system "./test"
  end
end
