class Sccache < Formula
  desc "Used as a compiler wrapper and avoids compilation when possible"
  homepage "https://github.com/mozilla/sccache"
  url "https://github.com/mozilla/sccache/archive/refs/tags/v0.17.0.tar.gz"
  sha256 "49949ad1cf175c49da126dbb0c2e6a56bd9d1f626e8cc0be17b9668b914145c6"
  license "Apache-2.0"
  revision 1
  head "https://github.com/mozilla/sccache.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41f2474e4d36b1de33f2bc8f8cea13814be19ce047f2a1a64538c5876f800111"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3" # Uses Secure Transport on macOS
  end

  def install
    system "cargo", "install", *std_cargo_args(features: "all")
  end

  test do
    (testpath/"hello.c").write <<~C
      #include <stdio.h>
      int main() {
        puts("Hello, world!");
        return 0;
      }
    C
    system bin/"sccache", "cc", "hello.c", "-o", "hello-c"
    assert_equal "Hello, world!", shell_output("./hello-c").chomp
  end
end
