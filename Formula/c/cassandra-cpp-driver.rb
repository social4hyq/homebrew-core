class CassandraCppDriver < Formula
  desc "DataStax C/C++ Driver for Apache Cassandra"
  homepage "https://docs.datastax.com/en/developer/cpp-driver/latest"
  url "https://github.com/apache/cassandra-cpp-driver/archive/refs/tags/2.17.1.tar.gz"
  sha256 "e6ab5f5c60a916dd6c0dd9a19a883a4a1ab3d6b4e95cab925a186fecff08344e"
  license "Apache-2.0"
  head "https://github.com/apache/cassandra-cpp-driver.git", branch: "trunk"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9492fb087307ba6f32af6dd3eb2521d46fb749faed21e2d246036f6111a5ba7b"
  end

  depends_on "cmake" => :build
  depends_on "libuv"
  depends_on "openssl@3"

  on_linux do
    depends_on "pkgconf" => :build
    depends_on "zlib-ng-compat"
  end

  def install
    # Fix to error: Unsupported compiler: AppleClang
    inreplace "CMakeLists.txt", 'STREQUAL "Clang"', 'STREQUAL "AppleClang"' if OS.mac?

    # Workaround for CMake 4 compatibility
    args = %W[
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
      -DLIBUV_ROOT_DIR=#{Formula["libuv"].opt_prefix}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <cassandra.h>

      int main(int argc, char* argv[]) {
        CassCluster* cluster = cass_cluster_new();
        CassSession* session = cass_session_new();

        CassFuture* future = cass_session_connect(session, cluster);

        // Because we haven't set any contact points, this connection
        // should fail even if a server is running locally
        CassError error = cass_future_error_code(future);
        if (error != CASS_OK) {
          printf("connection failed");
        }

        cass_future_free(future);

        cass_session_free(session);
        cass_cluster_free(cluster);

        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lcassandra", "-o", "test"
    assert_equal "connection failed", shell_output("./test")
  end
end
