class Libchaos < Formula
  desc "Advanced library for randomization, hashing and statistical analysis"
  homepage "https://github.com/maciejczyzewski/libchaos"
  url "https://github.com/maciejczyzewski/libchaos/releases/download/v1.0/libchaos-1.0.tar.gz"
  sha256 "29940ff014359c965d62f15bc34e5c182a6d8a505dc496c636207675843abd15"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e5adb974f1b2a038e5e14a900994d65e54f4adcd0082856a94c9b1d81b393778"
  end

  depends_on "cmake" => :build

  # Support for Xcode 15+ (LLVM 16+)
  patch :DATA

  def install
    args = %w[
      -DLIBCHAOS_ENABLE_TESTING=OFF
      -DSKIP_CCACHE=ON
    ]

    # Workaround to build with CMake 4
    inreplace "CMakeLists.txt", "CMAKE_POLICY(SET CMP0050 OLD)", ""
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "build"
    lib.install "build/libchaos.a"
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <chaos.h>
      #include <iostream>
      #include <string>

      int main(void) {
        std::cout << CHAOS_META_NAME(CHAOS_MACHINE_XORRING64) << std::endl;
        std::string hash = chaos::password<CHAOS_MACHINE_XORRING64, 175, 25, 40>(
            "some secret password", "my private salt");
        std::cout << hash << std::endl;
        if (hash.size() != 40)
          return 1;
        return 0;
      }
    CPP

    system ENV.cxx, "test.cc", "-std=c++11", "-L#{lib}", "-lchaos", "-o", "test"
    system "./test"
  end
end

__END__
diff --git a/include/chaos/analysis.hh b/include/chaos/analysis.hh
index 2b24d01..57423d1 100755
--- a/include/chaos/analysis.hh
+++ b/include/chaos/analysis.hh
@@ -37,15 +37,17 @@ class basic_adapter {
 	AP adapter;

 public:
+	using result_type = uint32_t;
+
 	void connect(AP func) { adapter = func; }
 	constexpr static size_t max(void) {
-		return std::numeric_limits<uint32_t>::max();
+		return std::numeric_limits<result_type>::max();
 	}
 	constexpr static size_t min(void) {
-		return std::numeric_limits<uint32_t>::lowest();
+		return std::numeric_limits<result_type>::lowest();
 	}
-	uint32_t operator()(void) noexcept {
-		return (uint32_t)(adapter() * (double)UINT32_MAX);
+	result_type operator()(void) noexcept {
+		return (result_type)(adapter() * (double)max());
 	}
 };
