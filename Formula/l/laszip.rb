class Laszip < Formula
  desc "Lossless LiDAR compression"
  homepage "https://laszip.org/"
  url "https://github.com/LASzip/LASzip/archive/refs/tags/3.5.0.tar.gz"
  sha256 "6e9baac8689dfd2e1502ceafabb20c62b6cd572744d240fb755503fd57c2a6af"
  license "Apache-2.0"
  head "https://github.com/LASzip/LASzip.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fdf7bcc4da5e9b1759e75ec9be163895035816938ee2c180058cfc9c5a7557f9"
  end

  depends_on "cmake" => :build

  # build patch to scope C++ standard flag, upstream pr ref, https://github.com/LASzip/LASzip/pull/122
  patch do
    url "https://github.com/LASzip/LASzip/commit/a2060ce7bbdde90774e067579fbfd1f53837a015.patch?full_index=1"
    sha256 "131816847a2e44df85e34c945e5e60f5112d94e6f9781c25316293832f08510c"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "example"
  end

  test do
    system ENV.cxx, pkgshare/"example/laszipdllexample.cpp", "-L#{lib}", "-I#{include}/laszip",
                    "-llaszip", "-llaszip_api", "-Wno-format", "-ldl", "-o", "test"
    assert_match "LASzip DLL", shell_output("./test -h 2>&1", 1)
  end
end
