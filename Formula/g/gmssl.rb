class Gmssl < Formula
  desc "Toolkit for Chinese national cryptographic standards"
  homepage "https://github.com/guanzhi/GmSSL"
  url "https://github.com/guanzhi/GmSSL/archive/refs/tags/v3.1.1.tar.gz"
  sha256 "23ed2ce74e408fc4c80289d2b499c7c5eec8373fefaf3827a53cb4c134dd5263"
  license "Apache-2.0"
  head "https://github.com/guanzhi/GmSSL.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b872b88de858722876178b047ec002f8771d2b7bbd3a8578f023da8a77bf52e2"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    expected_output = "ba7cc1a5be11d5f00dc8a88a9fedd74ccc9faf4655da08b7be3ae7e3954c76f1"
    output = pipe_output("#{bin}/gmssl sm3", "This is a test file").chomp
    assert_equal expected_output, output
  end
end
