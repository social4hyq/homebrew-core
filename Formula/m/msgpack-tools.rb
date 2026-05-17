class MsgpackTools < Formula
  desc "Command-line tools for converting between MessagePack and JSON"
  homepage "https://github.com/ludocode/msgpack-tools"
  url "https://github.com/ludocode/msgpack-tools/releases/download/v0.6/msgpack-tools-0.6.tar.gz"
  sha256 "98c8b789dced626b5b48261b047e2124d256e5b5d4fbbabdafe533c0bd712834"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "83bffc6bc7127a0437d3255ee1f76bd2dc4ab75bfe5acf6851326c94d3a72767"
  end

  depends_on "cmake" => :build

  conflicts_with "remarshal", because: "both install 'json2msgpack' binary"

  def install
    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    json_data = <<~JSON
      {"hello":"world"}
    JSON

    msgpack_data = pipe_output("#{bin}/json2msgpack", json_data)
    output = pipe_output("#{bin}/msgpack2json", msgpack_data)
    assert_equal json_data.strip, output.strip
  end
end
