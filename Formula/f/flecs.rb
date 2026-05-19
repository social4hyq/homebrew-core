class Flecs < Formula
  desc "Fast entity component system for C & C++"
  homepage "https://www.flecs.dev"
  url "https://github.com/SanderMertens/flecs/archive/refs/tags/v4.1.5.tar.gz"
  sha256 "8b94f56dfdda0b3c86110f651a4e0ec1c59030db43bb4810ae296a0630682ab9"
  license "MIT"
  head "https://github.com/SanderMertens/flecs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f7e0144d49151be2cefb5b53477a2f1ac9bbcbb7970bb5fe21456e5ee01036bf"
  end

  depends_on "cmake" => [:build, :test]

  def install
    system "cmake", "-S", ".", "-B", "builddir", *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"
  end

  test do
    (testpath/"main.c").write <<~C
      #include <flecs.h>

      int main(void) {
          ecs_world_t *world = ecs_init();
          ecs_fini(world);
          return 0;
      }
    C

    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required (VERSION #{Formula["cmake"].version})

      project(test LANGUAGES C)
      set(CMAKE_C_STANDARD 11)

      find_package(flecs CONFIG REQUIRED)
      add_executable(test main.c)
      target_link_libraries(test PRIVATE flecs::flecs)
    CMAKE

    system "cmake", "-S", ".", "-B", "build"
    system "cmake", "--build", "build"
    system "./build/test"
  end
end
