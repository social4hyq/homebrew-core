class Rttr < Formula
  desc "C++ Reflection Library"
  homepage "https://www.rttr.org"
  url "https://github.com/rttrorg/rttr/archive/refs/tags/v0.9.6.tar.gz"
  sha256 "058554f8644450185fd881a6598f9dee7ef85785cbc2bb5a5526a43225aa313f"
  license "MIT"
  head "https://github.com/rttrorg/rttr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "234fbd672f262b4c1ad8561b04eb97a4623d0eca0a6d2ce4539042f543740662"
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build

  def install
    args = %w[
      -DBUILD_UNIT_TESTS=OFF
      -DCMAKE_CXX_FLAGS=-Wno-deprecated-declarations
    ]

    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    hello_world = "Hello World"
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <rttr/registration>

      static void f() { std::cout << "#{hello_world}" << std::endl; }
      using namespace rttr;
      RTTR_REGISTRATION
      {
          using namespace rttr;
          registration::method("f", &f);
      }
      int main()
      {
          type::invoke("f", {});
      }
      // outputs: "Hello World"
    CPP
    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-lrttr_core", "-o", "test"
    assert_match hello_world, shell_output("./test")
  end
end
