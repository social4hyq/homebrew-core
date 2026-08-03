class Pegtl < Formula
  desc "Parsing Expression Grammar Template Library"
  homepage "https://github.com/taocpp/PEGTL"
  url "https://github.com/taocpp/PEGTL/archive/refs/tags/4.0.1.tar.gz"
  sha256 "ebc930bd9e3c37fd40771304cd3f318623ed87fe2880d17f514c080d16a12965"
  license "BSL-1.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c2394f9274c217a6dcf093b34214fb04b62563b4c659412b72ee64d77a173b4"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DPEGTL_BUILD_TESTS=OFF
      -DPEGTL_BUILD_EXAMPLES=OFF
      -DCMAKE_CXX_STANDARD=17
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    rm "src/example/CMakeLists.txt"
    (pkgshare/"examples").install (buildpath/"src/example").children
  end

  test do
    system ENV.cxx, pkgshare/"examples/hello_world.cpp", "-std=c++17", "-o", "helloworld"
    assert_equal "Good bye, homebrew!\n", shell_output("./helloworld 'Hello, homebrew!'")
  end
end
