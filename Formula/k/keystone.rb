class Keystone < Formula
  desc "Assembler framework: Core + bindings"
  homepage "https://github.com/keystone-engine/keystone"
  url "https://github.com/keystone-engine/keystone/archive/refs/tags/0.9.2.tar.gz"
  sha256 "c9b3a343ed3e05ee168d29daf89820aff9effb2c74c6803c2d9e21d55b5b7c24"
  license "GPL-2.0-only" # with FOSS License Exception (non-SPDX, see EXCEPTIONS-CLIENT)
  revision 1
  head "https://github.com/keystone-engine/keystone.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4c26b2ffa6a10b81cf7bfae76139a44aba034f6b177cd73abb98b3373fbb936f"
  end

  depends_on "cmake" => :build
  depends_on "python@3.14" => :build

  def python
    which("python3.14")
  end

  def install
    args = %W[
      -DPYTHON_EXECUTABLE=#{python}
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    # Workaround to build with CMake 4
    inreplace %w[CMakeLists.txt llvm/CMakeLists.txt],
              "cmake_policy(SET CMP0051 OLD)", ""
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

    # Build shared library
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Build static library
    system "cmake", "-S", ".", "-B", "static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "static"
    lib.install "static/llvm/lib/libkeystone.a"
  end

  test do
    assert_equal "nop = [ 90 ]", shell_output("#{bin}/kstool x16 nop").strip
  end
end
