class Rapidjson < Formula
  desc "JSON parser/generator for C++ with SAX and DOM style APIs"
  homepage "https://rapidjson.org/"
  license "MIT"
  head "https://github.com/Tencent/rapidjson.git", branch: "master"

  stable do
    url "https://github.com/Tencent/rapidjson/archive/refs/tags/v1.1.0.tar.gz"
    sha256 "bf7ced29704a1e696fbccf2a2b4ea068e7774fa37f6d7dd4039d0787f8bed98e"

    # Backport fix for usage with recent GCC and Clang
    patch do
      url "https://github.com/Tencent/rapidjson/commit/9bd618f545ab647e2c3bcbf2f1d87423d6edf800.patch?full_index=1"
      sha256 "ce341a69d6c17852fddd5469b6aabe995fd5e3830379c12746a18c3ae858e0e1"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1470239caed617c81ba6d17ef3d63cd97ec66e0473a6f36497baa86c26d5fef1"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    "-DRAPIDJSON_BUILD_DOC=OFF",
                    "-DRAPIDJSON_BUILD_EXAMPLES=OFF",
                    "-DRAPIDJSON_BUILD_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--install", "build"
  end

  test do
    system ENV.cxx, "#{share}/doc/RapidJSON/examples/capitalize/capitalize.cpp", "-o", "capitalize"
    assert_equal '{"A":"B"}', pipe_output("./capitalize", '{"a":"b"}')
  end
end
