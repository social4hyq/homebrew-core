class AwsCMqtt < Formula
  desc "C99 implementation of the MQTT 3.1.1 specification"
  homepage "https://github.com/awslabs/aws-c-mqtt"
  url "https://github.com/awslabs/aws-c-mqtt/archive/refs/tags/v0.16.0.tar.gz"
  sha256 "9bc044a9c2f0d80c384ae6a6907c8817e0b40f673f75c4615c83b20f83140374"
  license "Apache-2.0"
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13b194e9763f23314bb768cc2a82786bed70561ebcefc963f6f3d7aed4db76a0"
  end

  depends_on "cmake" => :build
  depends_on "aws-c-common"
  depends_on "aws-c-http"
  depends_on "aws-c-io"

  def install
    args = ["-DBUILD_SHARED_LIBS=ON"]
    # Avoid linkage to `aws-c-cal` and `aws-c-compression`
    args << "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-dead_strip_dylibs" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <aws/common/allocator.h>
      #include <aws/mqtt/mqtt.h>

      int main(void) {
        struct aws_allocator *allocator = aws_default_allocator();
        aws_mqtt_library_init(allocator);
        aws_mqtt_library_clean_up();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-laws-c-mqtt",
                   "-L#{Formula["aws-c-common"].opt_lib}", "-laws-c-common"
    system "./test"
  end
end
