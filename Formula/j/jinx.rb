class Jinx < Formula
  desc "Embeddable scripting language for real-time applications"
  homepage "https://github.com/JamesBoer/Jinx"
  url "https://github.com/JamesBoer/Jinx/archive/refs/tags/v1.3.10.tar.gz"
  sha256 "5b3a3e6c2c4b976dfdb16519aee7299c98dbf417b8179099a5509a5fd4d513ac"
  license "MIT"
  head "https://github.com/JamesBoer/Jinx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db77fe0233126c703c68639a6a50f7c3e03badd26ec7c8e374a4c81c85cdfa77"
  end

  depends_on "cmake" => :build

  def install
    # disable building tests
    inreplace "CMakeLists.txt", "if(NOT jinx_is_subproject)", "if(FALSE)"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    lib.install "build/libJinx.a"

    include.install Dir["Source/*.h"]
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "Jinx.h"

      int main() {
        // Create the Jinx runtime object
        auto runtime = Jinx::CreateRuntime();

        // Text containing our Jinx script
        const char * scriptText =
        u8R"(

        -- Use the core library
        import core

        -- Write to the debug output
        write line "Hello, world!"

        )";

        // Create and execute a script object
        auto script = runtime->ExecuteScript(scriptText);
      }
    CPP
    system ENV.cxx, "-std=c++17", "test.cpp", "-I#{include}", "-L#{lib}", "-lJinx", "-o", "test"
    assert_match "Hello, world!", shell_output("./test")
  end
end
