class Libswiftnav < Formula
  desc "C library implementing GNSS related functions and algorithms"
  homepage "https://github.com/swift-nav/libswiftnav"
  url "https://github.com/swift-nav/libswiftnav/archive/refs/tags/v2.4.2.tar.gz"
  sha256 "9dfe4ce4b4da28ffdb71acad261eef4dd98ad79daee4c1776e93b6f1765fccfa"
  license "LGPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1825ca60f4132c29ff88b6719cf76ce5330d2563a7add1ba802ec094f8093ab0"
  end

  depends_on "cmake" => :build

  # Check the `/cmake` directory for a given version tag
  # (e.g., https://github.com/swift-nav/libswiftnav/tree/v2.4.2/cmake)
  # to identify the referenced commit hash in the swift-nav/cmake repository.
  resource "swift-nav/cmake" do
    url "https://github.com/swift-nav/cmake/archive/fd8c86b87d2b18261691ef8db1f6fd9906911b82.tar.gz"
    sha256 "7b6995bcc97d001cfe5c4741a8fa3637bc4dc2c3460b908585aef5e7af268798"
  end

  def install
    (buildpath/"cmake/common").install resource("swift-nav/cmake")

    # Work around CMake compatibility issue. Remove with next release.
    inreplace "CMakeLists.txt", "cmake_minimum_required(VERSION 3.0)",
                                "cmake_minimum_required(VERSION 3.13)"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <stdio.h>
      #include <swiftnav/edc.h>

      const u8 *test_data = (u8*)"123456789";

      int main() {
        u32 crc;

        crc = crc24q(test_data, 9, 0xB704CE);
        if (crc != 0x21CF02) {
          printf("libswiftnav CRC quick test failed: CRC of \\"123456789\\" with init value 0xB704CE should be 0x21CF02, not 0x%06X\\n", crc);
          exit(1);
        } else {
          printf("libswiftnav CRC quick test successful, CRC = 0x21CF02\\n");
          exit(0);
        }
      }
    C
    system ENV.cc, "test.c", "-L", lib, "-lswiftnav", "-o", "test"
    system "./test"
  end
end
