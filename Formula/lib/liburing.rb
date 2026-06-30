class Liburing < Formula
  desc "Helpers to setup and teardown io_uring instances"
  homepage "https://github.com/axboe/liburing"
  # not need to check github releases, as tags are sufficient, see https://github.com/axboe/liburing/issues/1008
  url "https://github.com/axboe/liburing/archive/refs/tags/liburing-2.15.tar.gz"
  sha256 "8d052f2622dcb3678cbaee5ff582a87572672a6c0a56533cdda5b65cb636120a"
  license any_of: ["MIT", "LGPL-2.1-only"]
  head "https://github.com/axboe/liburing.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d3245aa8cd48919e08d8e1e5796b662a5f2253599d6e16bd6af5d7a612af153"
  end

  depends_on :linux

  def install
    # not autotools based configure, so std_configure_args is not suitable
    system "./configure", "--prefix=#{prefix}", "--libdir=#{lib}", "--mandir=#{man}"
    system "make"
    system "make", "install"
  end

  test do
    # io_uring_queue_init test is required to modify sysctl options or run as root
    # and so it is expected to fail in general
    (testpath/"test.c").write <<~C
      #include <liburing.h>
      #include <stdio.h>
      #include <string.h>

      int main() {
        struct io_uring ring;

        int ret = io_uring_queue_init(1, &ring, 0);
        if (ret < 0) {
          fprintf(stderr, "queue_init: %s", strerror(-ret));
          return 1;
        }

        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{opt_lib}", "-luring", "-o", "test"
    assert_match "queue_init: Operation not permitted", shell_output("./test 2>&1", 1)
  end
end
