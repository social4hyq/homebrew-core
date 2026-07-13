class Pcapplusplus < Formula
  desc "C++ network sniffing, packet parsing and crafting framework"
  homepage "https://pcapplusplus.github.io"
  url "https://github.com/seladb/PcapPlusPlus/archive/refs/tags/v26.07-test.tar.gz"
  version "26.07-test"
  sha256 "50502d988a97a6c1f8efc790769408b570f7652c3c312f1a35ea13ca61850c95"
  license "Unlicense"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7f1e84de19a504799869bb3fabcc4454b0215d7ff52f9819e3f39bb2837c34e3"
  end

  depends_on "cmake" => [:build, :test]
  uses_from_macos "libpcap"

  def install
    cmake_args = %w[
      -DPCAPPP_BUILD_EXAMPLES=OFF
      -DPCAPPP_BUILD_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *cmake_args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.12)
      project(TestPcapPlusPlus)
      set(CMAKE_CXX_STANDARD 11)

      find_package(PcapPlusPlus CONFIG REQUIRED)

      add_executable(test test.cpp)
      target_link_libraries(test PUBLIC PcapPlusPlus::Pcap++)
      set_target_properties(test PROPERTIES NO_SYSTEM_FROM_IMPORTED ON)
    CMAKE

    (testpath/"test.cpp").write <<~CPP
      #include <cstdlib>
      #include <pcapplusplus/PcapLiveDeviceList.h>
      int main() {
        const std::vector<pcpp::PcapLiveDevice*>& devList =
          pcpp::PcapLiveDeviceList::getInstance().getPcapLiveDevicesList();
        if (devList.size() > 0) {
          if (devList[0]->getName() == "")
            return 1;
          return 0;
        }
        return 0;
      }
    CPP

    system "cmake", "-S", ".", "-B", "build"
    system "cmake", "--build", "build", "--target", "test"
    system "./build/test"
  end
end
