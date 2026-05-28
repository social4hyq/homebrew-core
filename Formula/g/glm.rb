class Glm < Formula
  desc "C++ mathematics library for graphics software"
  homepage "https://glm.g-truc.net/"
  url "https://github.com/g-truc/glm/archive/refs/tags/1.0.3.tar.gz"
  sha256 "6775e47231a446fd086d660ecc18bcd076531cfedd912fbd66e576b118607001"
  # GLM is licensed under The Happy Bunny License or MIT License
  license "MIT"
  compatibility_version 1
  head "https://github.com/g-truc/glm.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "597c8f6a6dcdfdf80a1bda8995b1ff10f9e77d95af5430f7a58179813781ef99"
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build

  def install
    args = %w[
      -DGLM_BUILD_TESTS=OFF
      -DBUILD_SHARED_LIBS=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    include.install "glm"
    lib.install "cmake"
    (lib/"pkgconfig/glm.pc").write <<~EOS
      prefix=#{prefix}
      includedir=${prefix}/include

      Name: GLM
      Description: OpenGL Mathematics
      Version: #{version.to_s.match(/\d+\.\d+\.\d+/)}
      Cflags: -I${includedir}
    EOS

    cd "doc" do
      system "doxygen", "man.doxy"
      man.install "html"
    end
    doc.install Dir["doc/*"]
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <glm/vec2.hpp>// glm::vec2
      int main()
      {
        std::size_t const VertexCount = 4;
        std::size_t const PositionSizeF32 = VertexCount * sizeof(glm::vec2);
        glm::vec2 const PositionDataF32[VertexCount] =
        {
          glm::vec2(-1.0f,-1.0f),
          glm::vec2( 1.0f,-1.0f),
          glm::vec2( 1.0f, 1.0f),
          glm::vec2(-1.0f, 1.0f)
        };
        return 0;
      }
    CPP
    system ENV.cxx, "-I#{include}", testpath/"test.cpp", "-o", "test"
    system "./test"
  end
end
