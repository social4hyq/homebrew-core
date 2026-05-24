class Uncrustify < Formula
  desc "Source code beautifier"
  homepage "https://uncrustify.sourceforge.net/"
  url "https://github.com/uncrustify/uncrustify/archive/refs/tags/uncrustify-0.83.0.tar.gz"
  sha256 "1d4d3ab3a991c66eb24cb0a3e690573b4882fd98bc6ec64a01c283998c20dc87"
  license "GPL-2.0-or-later"
  head "https://github.com/uncrustify/uncrustify.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "20aab6214bbbff7c47a5f3a207c841b973d00abbe8d9e30f8f3da940b73219b4"
  end

  depends_on "cmake" => :build
  uses_from_macos "python" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    doc.install (buildpath/"documentation").children
  end

  test do
    (testpath/"t.c").write <<~C
      #include <stdio.h>
      int main(void) {return 0;}
    C

    expected = <<~C
      #include <stdio.h>
      int main(void) {
      \treturn 0;
      }
    C

    system bin/"uncrustify", "-c", doc/"htdocs/default.cfg", "t.c"
    assert_equal expected, (testpath/"t.c.uncrustify").read
  end
end
