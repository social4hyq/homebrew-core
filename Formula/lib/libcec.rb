class Libcec < Formula
  desc "Control devices with TV remote control and HDMI cabling"
  homepage "https://libcec.pulse-eight.com/"
  url "https://github.com/Pulse-Eight/libcec/archive/refs/tags/libcec-8.1.1.tar.gz"
  sha256 "0247a2e577cefceaa1932d9a2aec2b423e0ce9c77f90c2b8a99197fdd1a0b81d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88870a6e2869fe2be6f0172cb55a582aaeed865d24621e9baf278ebda272b9c9"
  end

  depends_on "cmake" => :build

  uses_from_macos "ncurses"

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match "libCEC version: #{version}", shell_output("#{bin}/cec-client --list-devices")
  end
end
