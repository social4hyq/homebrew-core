class Debugbreak < Formula
  desc "Break into the debugger programmatically"
  homepage "https://github.com/scottt/debugbreak"
  url "https://github.com/scottt/debugbreak/archive/refs/tags/v1.0.tar.gz"
  sha256 "62089680cc1cd0857519e2865b274ed7534bfa7ddfce19d72ffee41d4921ae2f"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "39f1f7feb7861bda4e378143de59c12c71255a3f3d7502318ac0896a1bd14c07"
  end

  def install
    include.install "debugbreak.h"
    pkgshare.install "debugbreak-gdb.py"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <debugbreak.h>
      int main() {
        debug_break(); /* will break into debugger */
        return 0;
      }
    C
    system ENV.cc, "-I#{include}", "test.c", "-o", "test"
    pid = Process.spawn("./test")
    assert_equal Signal.list.fetch("TRAP"), Process::Status.wait(pid).termsig
  end
end
