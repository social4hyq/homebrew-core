class Nuraft < Formula
  desc "C++ implementation of Raft core logic as a replication library"
  homepage "https://github.com/eBay/NuRaft"
  url "https://github.com/eBay/NuRaft/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "073c3b321efec9ce6b2bc487c283e493a1b2dd41082c5e9ac0b8f00f9b73832d"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "300d3284b7f4323e0a5365d98bdd8338f06424e94e31ebfb169e4ebe58d3f9e3"
  end

  depends_on "cmake" => :build

  depends_on "asio"
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # We override OPENSSL_LIBRARY_PATH to avoid statically linking to OpenSSL
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DOPENSSL_LIBRARY_PATH="
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "examples"
  end

  test do
    cp_r pkgshare/"examples/.", testpath
    system ENV.cxx, "-std=c++11", "-o", "test",
                    "quick_start.cxx", "logger.cc", "in_memory_log_store.cxx",
                    "-I#{include}/libnuraft", "-I#{testpath}/echo",
                    "-I#{Formula["openssl@3"].opt_include}",
                    "-L#{lib}", "-lnuraft",
                    "-L#{Formula["openssl@3"].opt_lib}", "-lcrypto", "-lssl"
    assert_match "hello world", shell_output("./test")
  end
end
