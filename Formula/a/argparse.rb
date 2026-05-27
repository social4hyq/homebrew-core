class Argparse < Formula
  desc "Argument Parser for Modern C++"
  homepage "https://github.com/p-ranav/argparse"
  url "https://github.com/p-ranav/argparse/archive/refs/tags/v3.2.tar.gz"
  sha256 "9dcb3d8ce0a41b2a48ac8baa54b51a9f1b6a2c52dd374e28cc713bab0568ec98"
  license "MIT"
  head "https://github.com/p-ranav/argparse.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db655e48de8cfff3a2da83285b9fb5222f37b3e89726c7a023b8f78138f70695"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <argparse/argparse.hpp>

      int main(int argc, char *argv[]) {
        argparse::ArgumentParser program("test");

        program.add_argument("--color").default_value(std::string{"orange"});
        program.parse_args(argc, argv);

        auto color = program.get<std::string>("--color");
        std::cout << "Color: " << color;
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++17", "-I#{include}", "-o", "test"
    assert_equal "Color: blue", shell_output("./test --color blue").strip
  end
end
