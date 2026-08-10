class Libcec < Formula
  desc "Control devices with TV remote control and HDMI cabling"
  homepage "https://libcec.pulse-eight.com/"
  url "https://github.com/Pulse-Eight/libcec/archive/refs/tags/libcec-8.1.6.tar.gz"
  sha256 "e1e762fee8589def3cbceb1f3e53ba06ed5b557a2705b86a225f8f30fb19c79a"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6dfd6138eb5a14f67936a83e097d2f2cb65e9c7dda93918fc4bb5e2b6afdfe56"
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
