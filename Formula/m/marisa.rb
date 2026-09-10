class Marisa < Formula
  desc "Matching Algorithm with Recursively Implemented StorAge"
  homepage "https://github.com/s-yata/marisa-trie"
  url "https://github.com/s-yata/marisa-trie/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "986ed5e2967435e3a3932a8c95980993ae5a196111e377721f0849cad4e807f3"
  license any_of: ["BSD-2-Clause", "LGPL-2.1-or-later"]
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a734ee3e70a287dac8ad56b641ea64c6748521f2246b7a35a20cb9b9e6ba7f51"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                     "-DBUILD_SHARED_LIBS=ON",
                     "-DCMAKE_INSTALL_RPATH=#{rpath}",
                     *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <cstdlib>
      #include <cstring>
      #include <ctime>
      #include <string>
      #include <iostream>
      #include <vector>

      #include <marisa.h>

      int main(void)
      {
        int x = 100, y = 200;
        marisa::swap(x, y);
        std::cout << x << "," << y << std::endl;
      }
    CPP

    system ENV.cxx, "-std=c++17", "./test.cc", "-o", "test"
    assert_equal "200,100", shell_output("./test").strip
  end
end
