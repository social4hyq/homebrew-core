class LibpahoMqtt < Formula
  desc "Eclipse Paho C client library for MQTT"
  homepage "https://eclipse-paho.github.io/paho.mqtt.c/MQTTClient/html/"
  url "https://github.com/eclipse-paho/paho.mqtt.c/archive/refs/tags/v1.3.16.tar.gz"
  sha256 "8b960f51edc7e03507637d987882bc486d8f4be6e79431bf99e2763344fd14c5"
  license "EPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02a37ed20b1e87514d7b9e056c201c6ff3fca7c368191cc815471feab3c780ba"
  end

  depends_on "cmake" => :build
  depends_on "openssl@3"

  patch do
    file "Patches/libpaho-mqtt/heap_pthread.patch"
  end

  def install
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DPAHO_WITH_SSL=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <MQTTClient.h>

      int main(int argc, char* argv[]) {
          MQTTClient client;
          MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer;

          return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lpaho-mqtt3a", "-o", "test"
    system "./test"
  end
end
