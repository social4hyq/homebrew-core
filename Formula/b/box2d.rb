class Box2d < Formula
  desc "2D physics engine for games"
  homepage "https://box2d.org"
  url "https://github.com/erincatto/box2d/archive/refs/tags/v3.1.1.tar.gz"
  sha256 "fb6ef914b50f4312d7d921a600eabc12318bb3c55a0b8c0b90608fa4488ef2e4"
  license "MIT"
  head "https://github.com/erincatto/Box2D.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "503eeb747e7f8bec4ae5ede302c42136c619b7da19da2de1fe6f9a09ca8be910"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DBOX2D_UNIT_TESTS=OFF
      -DBOX2D_SAMPLES=OFF
      -DBOX2D_BENCHMARKS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    include.install Dir["include/*"]
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <box2d/base.h>

      int main() {
        b2Version version = b2GetVersion();
        std::cout << "Box2D version: " << version.major << "." << version.minor << "." << version.revision << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-lbox2d", "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
