class OhosBstLight < Formula
  desc "Lightweight OpenHarmony binary self-signing tool"
  homepage "https://github.com/hqzing/ohos-bst-light"
  url "https://github.com/hqzing/ohos-bst-light/archive/refs/tags/v2.1.2.tar.gz"
  sha256 "707296b7263a5be14d412db689be20c32c20483f0760268ebd95b7306e4b95be"
  license "0BSD"

  def install
    system ENV.cc, "selfsign.c", "-o", "selfsign"
    bin.install "selfsign"
  end

  test do
    (testpath/"test.c").write <<~C
      int main() { return 0; }
    C
    system ENV.cc, "test.c", "-o", "test"
    system bin/"selfsign", "test"
    assert_match "already has a .codesign section", shell_output("#{bin}/selfsign test 2>&1", 3)
    system bin/"selfsign", "--force", "test"
    assert_match "strip ok", shell_output("#{bin}/selfsign --strip test 2>&1")
  end
end
