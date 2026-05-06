class ZlibNg < Formula
  desc "Zlib replacement with optimizations for next generation systems"
  homepage "https://github.com/zlib-ng/zlib-ng"
  url "https://github.com/zlib-ng/zlib-ng/archive/refs/tags/2.3.3.tar.gz"
  sha256 "f9c65aa9c852eb8255b636fd9f07ce1c406f061ec19a2e7d508b318ca0c907d1"
  license "Zlib"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "952cea824e80b4a8356df561ddf99fe12def8a9a2ca9a374a4a94965730e7b0b"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # https://zlib.net/zlib_how.html
    resource "homebrew-test_artifact" do
      url "https://zlib.net/zpipe.c"
      sha256 "e79717cefd20043fb78d730fd3b9d9cdf8f4642307fc001879dc82ddb468509f"
    end

    # Test uses an example of code for zlib and overwrites its API with zlib-ng API
    testpath.install resource("homebrew-test_artifact")
    inreplace "zpipe.c", "#include \"zlib.h\"", <<~C
      #include "zlib-ng.h"
      #define inflate     zng_inflate
      #define inflateInit zng_inflateInit
      #define inflateEnd  zng_inflateEnd
      #define deflate     zng_deflate
      #define deflateEnd  zng_deflateEnd
      #define deflateInit zng_deflateInit
      #define z_stream    zng_stream
    C

    system ENV.cc, "zpipe.c", "-I#{include}", "-L#{lib}", "-lz-ng", "-o", "zpipe"

    content = "Hello, Homebrew!"
    compressed = pipe_output("./zpipe", content)
    assert_equal content, pipe_output("./zpipe -d", compressed)
  end
end
