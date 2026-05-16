class Dragonbox < Formula
  desc "Reference implementation of Dragonbox in C++"
  homepage "https://github.com/jk-jeon/dragonbox"
  url "https://github.com/jk-jeon/dragonbox/archive/refs/tags/1.1.3.tar.gz"
  sha256 "09d63b05e9c594ec423778ab59b7a5aa1d76fdd71d25c7048b0258c4ec9c3384"
  license any_of: [
    "BSL-1.0",
    "Apache-2.0" => { with: "LLVM-exception" },
  ]
  head "https://github.com/jk-jeon/dragonbox.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e03ad54b630d6e962ed6e78766eb8a325b8ada2de4d408aa48ff31905fd38c07"
  end

  depends_on "cmake" => [:build, :test]

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 4.0)
      project(TestDragonbox)

      find_package(dragonbox REQUIRED)
      add_executable(test_dragonbox test.cpp)

      target_link_libraries(test_dragonbox PRIVATE dragonbox::dragonbox_to_chars)
    CMAKE

    (testpath/"test.cpp").write <<~CPP
      #include <dragonbox/dragonbox_to_chars.h>
      #include <iostream>

      int main() {
        double number = 123.456;
        char buffer[25];
        jkj::dragonbox::to_chars(number, buffer);
        std::cout << buffer << std::endl;
        return 0;
      }
    CPP

    system "cmake", "-S", ".", "-B", "build"
    system "cmake", "--build", "build"

    assert_match "1.23456E2", shell_output("./build/test_dragonbox")
  end
end
