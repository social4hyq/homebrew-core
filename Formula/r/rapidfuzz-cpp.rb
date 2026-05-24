class RapidfuzzCpp < Formula
  desc "Rapid fuzzy string matching in C++ using the Levenshtein Distance"
  homepage "https://rapidfuzz.github.io/rapidfuzz-cpp/"
  url "https://github.com/rapidfuzz/rapidfuzz-cpp/archive/refs/tags/v3.3.3.tar.gz"
  sha256 "fa0fbd40110df8134cf05bddbaa4e237dbc4fd915ab9a3029ff481a8d3e8b757"
  license "MIT"
  head "https://github.com/rapidfuzz/rapidfuzz-cpp.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54053c2052b4887cb39108899646e6070378c3b0633ad88b6b951e6e0c39d00c"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <rapidfuzz/fuzz.hpp>
      #include <string>
      #include <iostream>

      int main()
      {
          std::string a = "aaaa";
          std::string b = "abab";
          std::cout << rapidfuzz::fuzz::ratio(a, b) << std::endl;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++17", "-I#{include}", "-o", "test"
    assert_equal "50", shell_output("./test").strip
  end
end
