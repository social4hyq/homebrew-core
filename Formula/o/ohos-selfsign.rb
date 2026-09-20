class OhosSelfsign < Formula
  desc "Lightweight OpenHarmony binary self-signing tool"
  homepage "https://github.com/hqzing/ohos-selfsign"
  url "https://github.com/hqzing/ohos-selfsign/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "d66c9ed4442aa876643a477db1fc77bb48f088b221f2bc3aee21861b937166c4"
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
