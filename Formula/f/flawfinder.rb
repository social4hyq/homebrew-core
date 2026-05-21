class Flawfinder < Formula
  include Language::Python::Shebang

  desc "Examines code and reports possible security weaknesses"
  homepage "https://dwheeler.com/flawfinder/"
  url "https://dwheeler.com/flawfinder/flawfinder-2.0.20.tar.gz"
  sha256 "9d732a4e0fef1cd4eaeefd4a0093f183c5981f6c843711ceae6a63419404996b"
  license "GPL-2.0-or-later"
  head "https://github.com/david-a-wheeler/flawfinder.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?flawfinder[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01858fcd1ebe81f077f1464d9d32a4db625b3e92e400e8ff4102ce84e2418838"
  end

  depends_on "python@3.14"

  def install
    rewrite_shebang detected_python_shebang, "flawfinder.py"
    system "make", "prefix=#{prefix}", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      int demo(char *a, char *b) {
        strcpy(a, "\n");
        strcpy(a, gettext("Hello there"));
      }
    C
    assert_match("Hits = 2\n", shell_output("#{bin}/flawfinder test.c"))
  end
end
