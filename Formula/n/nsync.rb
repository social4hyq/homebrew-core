class Nsync < Formula
  desc "C library that exports various synchronization primitives"
  homepage "https://github.com/google/nsync"
  url "https://github.com/google/nsync/archive/refs/tags/1.30.0.tar.gz"
  sha256 "883a0b3f8ffc1950670425df3453c127c1a3f6ed997719ca1bbe7f474235b6cc"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92056c260d3147c97c8bb26e51972e1b2abb7edfec9013696ba6ae0a0dc5fc33"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DNSYNC_ENABLE_TESTS=OFF
    ]
    system "cmake", "-S", ".", "-B", "_build", *args, *std_cmake_args
    system "cmake", "--build", "_build"
    system "cmake", "--install", "_build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nsync.h>
      #include <stdio.h>

      int main() {
        nsync_mu mu;
        nsync_mu_init(&mu);
        nsync_mu_lock(&mu);
        nsync_mu_unlock(&mu);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lnsync", "-o", "test"
    system "./test"
  end
end
