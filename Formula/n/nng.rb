class Nng < Formula
  desc "Nanomsg-next-generation -- light-weight brokerless messaging"
  homepage "https://nng.nanomsg.org/"
  url "https://github.com/nanomsg/nng/archive/refs/tags/v1.12.2.tar.gz"
  sha256 "a6e03b6cb3c8c7abb371b9a58e0f070b9cd7bed132999032aa8fcd084cd7787f"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "762f205d26560752f73cf9618e609fea7fe6693aa8e5429bf785f4778bf49fce"
  end

  depends_on "asciidoctor" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
                    "-DNNG_ENABLE_DOC=ON",
                    "-DBUILD_SHARED_LIBS=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    bind = "tcp://127.0.0.1:#{free_port}"

    fork do
      exec "#{bin}/nngcat --rep --bind #{bind} --format ascii --data home"
    end
    sleep 2

    output = shell_output("#{bin}/nngcat --req --connect #{bind} --format ascii --data brew")
    assert_match(/home/, output)
  end
end
