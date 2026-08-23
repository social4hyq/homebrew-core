class UmkaLang < Formula
  desc "Statically typed embeddable scripting language"
  homepage "https://github.com/vtereshkov/umka-lang"
  url "https://github.com/vtereshkov/umka-lang/archive/refs/tags/v1.5.7.tar.gz"
  sha256 "b4dce5652a7e974e9ad63182f74b6033269b2d3ecad81b7d88f093816446e646"
  license "BSD-2-Clause"
  head "https://github.com/vtereshkov/umka-lang.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "09c62df78f99a70982e8e21c3a6312ed51fb43370bfc023030c7e8509d461cc2"
  end

  def install
    # Workaround to build on arm64 linux
    if OS.linux? && Hardware::CPU.arm?
      inreplace "Makefile" do |s|
        cflags = s.get_make_var("CFLAGS").split
        s.change_make_var! "CFLAGS", cflags.join(" ") if cflags.delete("-malign-double")
      end
    end

    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"hello.um").write <<~UMKA
      fn main() {
        printf("Hello Umka!")
      }
    UMKA

    assert_match "Hello Umka!", shell_output("#{bin}/umka #{testpath}/hello.um")

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <umka_api.h>
      int main(void) {
          printf("Umka version: %s\\n", umkaGetVersion());
          return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lumka", "-o", "test"
    system "./test"
  end
end
