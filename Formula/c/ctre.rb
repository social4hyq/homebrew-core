class Ctre < Formula
  desc "Compile-time regular expression matcher for C++"
  homepage "https://compile-time-regular-expressions.readthedocs.io/"
  url "https://github.com/hanickadot/compile-time-regular-expressions/archive/refs/tags/v3.11.0.tar.gz"
  sha256 "7d4b30d0bdd8864a47cceb2ab8e7c4d1846f0ec62383f8c45122435d32f19530"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4c718692e5e547c50b3f461f407fe9c911adbe4e6e0c4ffa6bf215c3033bae2c"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c++").write <<~'CXX'
      #include <ctre-unicode.hpp>

      int main()
      {
        constexpr auto url = "https://github.com/org/repo/archive/refs/tags/v1.6.18.tar.gz";
        constexpr auto regex = ctll::fixed_string{R"(\d+(?:\.\d+)+)"};
        constexpr auto version = ctre::search<regex>(url);
        static_assert(version && version.get<0>() == "1.6.18");
      }
    CXX
    system ENV.cxx, "test.c++", "-o", "test", "-std=c++20", "-I#{include}"
    system "./test"
  end
end
