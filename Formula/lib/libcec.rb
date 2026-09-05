class Libcec < Formula
  desc "Control devices with TV remote control and HDMI cabling"
  homepage "https://libcec.pulse-eight.com/"
  url "https://github.com/Pulse-Eight/libcec/archive/refs/tags/libcec-8.1.7.tar.gz"
  sha256 "e4ac4d1dd3559cf83189d29ab40fc5537b5a2beceb82916ef173dac7e50dbfa0"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36e0e16601a593f77105a15b0a3aeaf9aa562de18436bbf641d82acf0217e181"
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
