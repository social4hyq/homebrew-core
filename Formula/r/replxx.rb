class Replxx < Formula
  desc "Readline and libedit replacement"
  homepage "https://github.com/AmokHuginnsson/replxx"
  url "https://github.com/AmokHuginnsson/replxx/archive/refs/tags/release-0.0.4.tar.gz"
  sha256 "a22988b2184e1d256e2d111b5749e16ffb1accbf757c7b248226d73c426844c4"
  license all_of: ["BSD-3-Clause", "Unicode-TOU"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "913c9cb9ef38e55bd2069a72cf2340e81a9cce3d9c263e75165361d3b84d4760"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "examples"
  end

  test do
    cp_r pkgshare/"examples", testpath
    cd "examples" do
      system ENV.cc, "-c", "util.c", "-o", "util.o"
      system ENV.cc, "c-api.c", "util.o", "-L#{lib}", "-I#{include}", "-lreplxx", "-lm", "-o", "test"

      # `test` executable is an interactive program so we use Open3 to interact with it
      Open3.popen3("./test") do |stdin, stdout, stderr, _|
        sleep 2
        assert_match "starting...", stdout.gets

        stdin.puts "hello"
        sleep 2

        assert_match "thanks for the input: hello", stdout.gets

        stdin.close # simulate Ctrl+D by closing stdin

        assert_empty stderr.read
      end
    end
  end
end
