class Wren < Formula
  desc "Small, fast, class-based concurrent scripting language"
  homepage "https://wren.io"
  url "https://github.com/wren-lang/wren/archive/refs/tags/0.4.0.tar.gz"
  sha256 "23c0ddeb6c67a4ed9285bded49f7c91714922c2e7bb88f42428386bf1cf7b339"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a2f1c910561beadd49b4f8cccf95eec85d092f10b0e6007d7ac8936f627949b"
  end

  def install
    if OS.mac?
      system "make", "-C", "projects/make.mac"
    else
      system "make", "-C", "projects/make"
    end
    lib.install Dir["lib/*"]
    include.install Dir["src/include/*"]
    pkgshare.install "example"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <stdio.h>
      #include "wren.h"

      int main()
      {
        WrenConfiguration config;
        wrenInitConfiguration(&config);
        WrenVM* vm = wrenNewVM(&config);
        WrenInterpretResult result = wrenInterpret(vm, "test", "var result = 1 + 2");
        assert(result == WREN_RESULT_SUCCESS);
        wrenEnsureSlots(vm, 0);
        wrenGetVariable(vm, "test", "result", 0);
        printf("1 + 2 = %d\\n", (int) wrenGetSlotDouble(vm, 0));
        wrenFreeVM(vm);
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lwren", "-o", "test"
    assert_equal "1 + 2 = 3", shell_output("./test").strip
  end
end
