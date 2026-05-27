class Utf8cpp < Formula
  desc "UTF-8 with C++ in a Portable Way"
  homepage "https://github.com/nemtrif/utfcpp"
  url "https://github.com/nemtrif/utfcpp/archive/refs/tags/v4.1.1.tar.gz"
  sha256 "1ca68016f0abc24172998e39ce0d8f8e2b7a26f7579a0ff85d4e1b9a7aea56f8"
  license "BSL-1.0"
  version_scheme 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f25eda437d93d7113b269ed34a124c6e0ddf1b16e4c907b05a3facbc34c72e9a"
  end

  depends_on "cmake" => [:build, :test]

  def install
    # Temporary fix, remove in next release
    inreplace "CMakeLists.txt", "VERSION 4.1.0", "VERSION #{version}"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match("PACKAGE_VERSION \"#{version}\"", (share/"utf8cpp/cmake/utf8cppConfigVersion.cmake").read)

    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 4.0 FATAL_ERROR)
      project(utf8_append LANGUAGES CXX)
      find_package(utf8cpp REQUIRED CONFIG)
      add_executable(utf8_append utf8_append.cpp)
    CMAKE

    (testpath/"utf8_append.cpp").write <<~CPP
      #include <utf8cpp/utf8.h>
      int main() {
        unsigned char u[5] = {0, 0, 0, 0, 0};
        utf8::append(0x0448, u);
        return (u[0] == 0xd1 && u[1] == 0x88 && u[2] == 0 && u[3] == 0 && u[4] == 0) ? 0 : 1;
      }
    CPP

    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_PREFIX_PATH=#{opt_lib}", "-DCMAKE_VERBOSE_MAKEFILE=ON"
    system "cmake", "--build", "build"
    system "./build/utf8_append"
  end
end
