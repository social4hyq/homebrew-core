class Shaderc < Formula
  desc "Collection of tools, libraries, and tests for Vulkan shader compilation"
  homepage "https://github.com/google/shaderc"
  license "Apache-2.0"

  stable do
    url "https://github.com/google/shaderc/archive/refs/tags/v2026.4.tar.gz"
    sha256 "f06ce5bcca94e5df7f34e115743597d0ad2e13c5fe9213c67dc8c76031241947"

    resource "glslang" do
      # https://github.com/google/shaderc/blob/DEPS
      url "https://github.com/KhronosGroup/glslang.git",
          revision: "168d452a4f460d24b588fed08477a81c44ee27a1"
      version "168d452a4f460d24b588fed08477a81c44ee27a1"

      livecheck do
        url "https://raw.githubusercontent.com/google/shaderc/refs/tags/v#{LATEST_VERSION}/DEPS"
        regex(/["']glslang_revision["']:\s*["']([0-9a-f]+)["']/i)
      end
    end

    resource "spirv-headers" do
      # https://github.com/google/shaderc/blob/DEPS
      url "https://github.com/KhronosGroup/SPIRV-Headers.git",
          revision: "29981f65241605e08b0ede4cfeb999fe3b723c6a"
      version "29981f65241605e08b0ede4cfeb999fe3b723c6a"

      livecheck do
        url "https://raw.githubusercontent.com/google/shaderc/refs/tags/v#{LATEST_VERSION}/DEPS"
        regex(/["']spirv_headers_revision["']:\s*["']([0-9a-f]+)["']/i)
      end
    end

    resource "spirv-tools" do
      # https://github.com/google/shaderc/blob/DEPS
      url "https://github.com/KhronosGroup/SPIRV-Tools.git",
          revision: "b707790a898e44038547df54580022fc1cf89c3d"
      version "b707790a898e44038547df54580022fc1cf89c3d"

      livecheck do
        url "https://raw.githubusercontent.com/google/shaderc/refs/tags/v#{LATEST_VERSION}/DEPS"
        regex(/["']spirv_tools_revision["']:\s*["']([0-9a-f]+)["']/i)
      end
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3136a241949529f6fcd5c0a2af6166920d22abd9dd171c77b20f7acb2c6e2134"
  end

  head do
    url "https://github.com/google/shaderc.git", branch: "main"

    resource "glslang" do
      url "https://github.com/KhronosGroup/glslang.git", branch: "main"
    end

    resource "spirv-tools" do
      url "https://github.com/KhronosGroup/SPIRV-Tools.git", branch: "main"
    end

    resource "spirv-headers" do
      url "https://github.com/KhronosGroup/SPIRV-Headers.git", branch: "main"
    end
  end

  depends_on "cmake" => :build

  uses_from_macos "python" => :build

  def install
    resources.each do |res|
      res.stage(buildpath/"third_party"/res.name)
    end

    # Avoid installing packages that conflict with other formulae.
    inreplace "third_party/CMakeLists.txt", "${SHADERC_SKIP_INSTALL}", "ON"
    # patch to fix `target "SPIRV-Tools-opt" that is not in any export set`
    # upstream bug report, https://github.com/google/shaderc/issues/1413
    inreplace "third_party/CMakeLists.txt",
              "set(GLSLANG_ENABLE_INSTALL $<NOT:${SKIP_GLSLANG_INSTALL}>)", ""

    system "cmake", "-S", ".", "-B", "build",
                    "-DSHADERC_SKIP_TESTS=ON",
                    "-DSKIP_GLSLANG_INSTALL=ON",
                    "-DSKIP_SPIRV_TOOLS_INSTALL=ON",
                    "-DSKIP_GOOGLETEST_INSTALL=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <shaderc/shaderc.h>
      int main() {
        int version;
        shaderc_profile profile;
        if (!shaderc_parse_version_profile("450core", &version, &profile))
          return 1;
        return (profile == shaderc_profile_core) ? 0 : 1;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{include}",
                   "-L#{lib}", "-lshaderc_shared"
    system "./test"
  end
end
