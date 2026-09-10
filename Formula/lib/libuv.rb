class Libuv < Formula
  desc "Multi-platform support library with a focus on asynchronous I/O"
  homepage "https://libuv.org/"
  url "https://dist.libuv.org/dist/v1.52.1/libuv-v1.52.1.tar.gz"
  sha256 "66d511b9e6e334c0e62279eb234fbfb2b3110b1479c09b95b44c7afca8cff9e7"
  license "MIT"
  revision 1
  compatibility_version 1
  head "https://github.com/libuv/libuv.git", branch: "v1.x"

  livecheck do
    url :head
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a29bb244fe95ef5aa619b9915d2170a39b683af4f004b467382ad4491aa9b2f7"
  end

  depends_on "cmake" => :build
  depends_on "sphinx-doc" => :build

  def install
    # This isn't yet handled by the make install process sadly.
    system "make", "-C", "docs", "man"
    man1.install "docs/build/man/libuv.1"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <uv.h>
      #include <stdlib.h>

      int main()
      {
        uv_loop_t* loop = malloc(sizeof *loop);
        uv_loop_init(loop);
        uv_loop_close(loop);
        free(loop);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-luv", "-o", "test"
    system "./test"
  end
end
