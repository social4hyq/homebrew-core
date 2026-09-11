class Libraqm < Formula
  desc "Library for complex text layout"
  homepage "https://github.com/HOST-Oman/libraqm"
  url "https://github.com/HOST-Oman/libraqm/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "2ba3521d3f24e9696185a67a16f1a9643429d6c897d89d83dfb2aad3a398732a"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a0055931b0995c6592e8a84c904398c4f09bd6d355bc889c882c2a776bdd8b70"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "freetype"
  depends_on "fribidi"
  depends_on "harfbuzz"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <raqm.h>

      int main() {
        return 0;
      }
    C

    system ENV.cc, "test.c",
                   "-I#{include}",
                   "-I#{Formula["freetype"].include/"freetype2"}",
                   "-o", "test"
    system "./test"
  end
end
