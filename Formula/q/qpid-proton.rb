class QpidProton < Formula
  desc "High-performance, lightweight AMQP 1.0 messaging library"
  homepage "https://qpid.apache.org/proton/"
  url "https://www.apache.org/dyn/closer.lua?path=qpid/proton/0.40.0/qpid-proton-0.40.0.tar.gz"
  mirror "https://archive.apache.org/dist/qpid/proton/0.40.0/qpid-proton-0.40.0.tar.gz"
  sha256 "0acb39e92d947e30175de0969a5b2e479e2983bc3e3d69c835ee5174610e9636"
  license "Apache-2.0"
  head "https://gitbox.apache.org/repos/asf/qpid-proton.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "017bcc997839a0c55583939d816a91b4dd73354b8e310c110937b1be8db21feb"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libuv"
  depends_on "openssl@3"

  uses_from_macos "python" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_BINDINGS=",
                    "-DLIB_INSTALL_DIR=#{lib}",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-Dproactor=libuv",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "proton/message.h"
      #include "proton/messenger.h"
      int main()
      {
          pn_message_t * message;
          pn_messenger_t * messenger;
          pn_data_t * body;
          message = pn_message();
          messenger = pn_messenger(NULL);
          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lqpid-proton", "-o", "test"
    system "./test"
  end
end
