class Cjson < Formula
  desc "Ultralightweight JSON parser in ANSI C"
  homepage "https://github.com/DaveGamble/cJSON"
  url "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.19.tar.gz"
  sha256 "7fa616e3046edfa7a28a32d5f9eacfd23f92900fe1f8ccd988c1662f30454562"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3fd4f23572ba5ffb57ece5ba4871980de953f2200d3777b43ae31a9bcea7a4f2"
  end

  depends_on "cmake" => :build

  # CMake 4 build patch
  # PR ref: https://github.com/DaveGamble/cJSON/pull/949
  patch do
    url "https://github.com/DaveGamble/cJSON/commit/887642c0a93bd8a6616bf90daacac0ea7d4b095e.patch?full_index=1"
    sha256 "98c2d5ef6cf325ccd089bf4301b0d07e453d4c6276d38a36306c50f106baec82"
  end

  def install
    args = %W[
      -DENABLE_CJSON_UTILS=ON
      -DENABLE_CJSON_TEST=Off
      -DBUILD_SHARED_AND_STATIC_LIBS=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <cjson/cJSON.h>

      int main()
      {
        char *s = "{\\"key\\":\\"value\\"}";
        cJSON *json = cJSON_Parse(s);
        if (!json) {
            return 1;
        }
        cJSON *item = cJSON_GetObjectItem(json, "key");
        if (!item) {
            return 1;
        }
        cJSON_Delete(json);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lcjson", "-o", "test"
    system "./test"
  end
end
