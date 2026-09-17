class AtomicQueue < Formula
  desc "C++14 lock-free queues"
  homepage "https://github.com/max0x7ba/atomic_queue"
  url "https://github.com/max0x7ba/atomic_queue/archive/refs/tags/v1.9.4.tar.gz"
  sha256 "fecfa9ca12fc203e40fd967c2bfa8033f77d0bde0e3b21c8ca5f5f9eeeabe022"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "264c380691055aad21e04a9fb442885949d5036343d8eeda2af6b4b1bf32db01"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :test

  def install
    system "meson", "setup", "build", "-Dtests=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <cassert>
      #include <memory>
      #include <atomic_queue/atomic_queue.h>

      int main() {
          using QueueT = atomic_queue::AtomicQueueB2<int, std::allocator<int>, true, true, true>;
          auto queue = QueueT(64);
          queue.push(5);
          assert(queue.was_size() == 1);
          assert(queue.pop() == 5);
          return 0;
      }
    CPP

    flags = shell_output("pkgconf --cflags --libs atomic_queue").chomp.split
    system ENV.cxx, "test.cpp", "-o", "test", "-std=c++14", *flags
    system "./test"
  end
end
