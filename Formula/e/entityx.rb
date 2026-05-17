class Entityx < Formula
  desc "Fast, type-safe C++ Entity Component System"
  homepage "https://github.com/alecthomas/entityx"
  url "https://github.com/alecthomas/entityx/archive/refs/tags/1.3.0.tar.gz"
  sha256 "2cd56d4fc5c553b786b8caf0b5bd9231434f21d43ca0e963d3bc5ee503a06222"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de8a24920a59452f6a1644d31fab4dde996761e8d23b8f0878e78d0368ffefb4"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DENTITYX_BUILD_SHARED=off
      -DENTITYX_BUILD_TESTING=off
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <entityx/entityx.h>

      int main(int argc, char *argv[]) {
        entityx::EntityX ex;

        entityx::Entity entity = ex.entities.create();
        entity.destroy();

        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++11", "-L#{lib}", "-lentityx", "-o", "test"
    system "./test"
  end
end
