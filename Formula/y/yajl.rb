class Yajl < Formula
  desc "Yet Another JSON Library"
  homepage "https://lloyd.github.io/yajl/"
  url "https://github.com/lloyd/yajl/archive/refs/tags/2.1.0.tar.gz"
  sha256 "3fb73364a5a30efe615046d07e6db9d09fd2b41c763c5f7d3bfb121cd5c5ac5a"
  license "ISC"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ad53a9839abd4f9a625508c4e43b5f3ac7e44ee32eb1073de80f52234036cf7"
  end

  depends_on "cmake" => :build

  # Workaround to build with CMake 4
  patch do
    url "https://github.com/lloyd/yajl/commit/6fe59ca50dfd65bdb3d1c87a27245b2dd1a072f9.patch?full_index=1"
    sha256 "b059e4181aca7c50c71924632b5e1dc263ea05a2e7fc6def095c0cc65398282c"
  end

  def install
    ENV.deparallelize

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    (include/"yajl").install Dir["src/api/*.h"]
  end

  test do
    output = pipe_output("#{bin}/json_verify", "[0,1,2,3]").strip
    assert_equal "JSON is valid", output
  end
end
