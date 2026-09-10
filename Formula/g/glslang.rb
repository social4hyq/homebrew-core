class Glslang < Formula
  desc "OpenGL and OpenGL ES reference compiler for shading languages"
  homepage "https://www.khronos.org/opengles/sdk/Reference-Compiler/"
  url "https://github.com/KhronosGroup/glslang/archive/refs/tags/16.5.0.tar.gz"
  sha256 "01af17195fbeb59e39e31e9506de35bb39dfd35807ea0c9a1a99d7d1183ddd45"
  license all_of: ["BSD-3-Clause", "GPL-3.0-or-later", "MIT", "Apache-2.0"]
  revision 1
  compatibility_version 1
  head "https://github.com/KhronosGroup/glslang.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5dcb3290fbba0c719a3cc644903ef919f8a5774a88a71c49ec935552a1eea57b"
  end

  depends_on "cmake" => :build
  depends_on "spirv-headers"
  depends_on "spirv-tools"

  uses_from_macos "python" => :build

  def install
    args = %W[
      -DBUILD_EXTERNAL=OFF
      -DALLOW_EXTERNAL_SPIRV_TOOLS=ON
      -DBUILD_SHARED_LIBS=ON
      -DENABLE_CTEST=OFF
      -DENABLE_OPT=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.frag").write <<~EOS
      #version 110
      void main() {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
      }
    EOS

    (testpath/"test.vert").write <<~EOS
      #version 110
      void main() {
          gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
      }
    EOS

    system bin/"glslangValidator", "-i", testpath/"test.vert", testpath/"test.frag"
  end
end
