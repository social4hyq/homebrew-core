class Srt < Formula
  desc "Secure Reliable Transport"
  homepage "https://www.srtalliance.org/"
  url "https://github.com/Haivision/srt/archive/refs/tags/v1.5.7.tar.gz"
  sha256 "fee6aee6b4933f01ba8b7e18d5d9e4896ad604053fdad2ac55df4a4f1561f30a"
  license "MPL-2.0"
  compatibility_version 1
  head "https://github.com/Haivision/srt.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "deb32b40cfd77a85fe189899947a0fda343bd0cbaa620b63adc571e792cb7e03"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    openssl = Formula["openssl@3"]

    args = %W[
      -DWITH_OPENSSL_INCLUDEDIR=#{openssl.opt_include}
      -DWITH_OPENSSL_LIBDIR=#{openssl.opt_lib}
      -DCMAKE_INSTALL_BINDIR=bin
      -DCMAKE_INSTALL_LIBDIR=lib
      -DCMAKE_INSTALL_INCLUDEDIR=include
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    cmd = "#{bin}/srt-live-transmit file:///dev/null file://con/ 2>&1"
    assert_match "Unsupported source type", shell_output(cmd, 1)
  end
end
