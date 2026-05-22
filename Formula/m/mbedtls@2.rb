class MbedtlsAT2 < Formula
  desc "Cryptographic & SSL/TLS library"
  homepage "https://tls.mbed.org/"
  url "https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-2.28.10.tar.gz"
  sha256 "c785ddf2ad66976ab429c36dffd4a021491e40f04fe493cfc39d6ed9153bc246"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9743a186024538a11d67c8af4af4f3a132f65523d133899ac522a734669ac415"
  end

  keg_only :versioned_formula

  # mbedtls-2.28 maintained until the end of 2024
  # Ref: https://github.com/Mbed-TLS/mbedtls/blob/development/BRANCHES.md#current-branches
  deprecate! date: "2025-03-31", because: :unsupported
  disable! date: "2026-03-31", because: :unsupported

  depends_on "cmake" => :build
  depends_on "python@3.12" => :build

  def install
    inreplace "include/mbedtls/config.h" do |s|
      # enable pthread mutexes
      s.gsub! "//#define MBEDTLS_THREADING_PTHREAD", "#define MBEDTLS_THREADING_PTHREAD"
      # allow use of mutexes within mbed TLS
      s.gsub! "//#define MBEDTLS_THREADING_C", "#define MBEDTLS_THREADING_C"
    end

    args = %W[
      -DUSE_SHARED_MBEDTLS_LIBRARY=On
      -DPython3_EXECUTABLE=#{which("python3.12")}
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    # Workaround for CMake 4 compatibility
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"

    # We run CTest because this is a crypto library. Running tests in parallel causes failures.
    # https://github.com/Mbed-TLS/mbedtls/issues/4980
    with_env(CC: DevelopmentTools.locate(DevelopmentTools.default_compiler)) do
      system "ctest", "--parallel", "1", "--test-dir", "build", "--rerun-failed", "--output-on-failure"
    end
    system "cmake", "--install", "build"

    # Why does Mbedtls ship with a "Hello World" executable. Let's remove that.
    rm(bin/"hello")
    # Rename benchmark & selftest, which are awfully generic names.
    mv bin/"benchmark", bin/"mbedtls-benchmark"
    mv bin/"selftest", bin/"mbedtls-selftest"
    # Demonstration files shouldn't be in the main bin
    libexec.install bin/"mpi_demo"
  end

  test do
    (testpath/"testfile.txt").write("This is a test file")
    # Don't remove the space between the checksum and filename. It will break.
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249  testfile.txt"
    assert_equal expected_checksum, shell_output("#{bin}/generic_sum SHA256 testfile.txt").strip
  end
end
