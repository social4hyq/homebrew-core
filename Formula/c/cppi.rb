class Cppi < Formula
  desc "Indent C preprocessor directives to reflect their nesting"
  homepage "https://www.gnu.org/software/cppi/"
  url "https://ftpmirror.gnu.org/gnu/cppi/cppi-1.18.tar.xz"
  mirror "https://ftp.gnu.org/gnu/cppi/cppi-1.18.tar.xz"
  sha256 "12a505b98863f6c5cf1f749f9080be3b42b3eac5a35b59630e67bea7241364ca"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1393d2009bb9b19932003745473368f233b4476274b4f065bf059bb4f29faa6e"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    test = <<~C
      #ifdef TEST
      #include <homebrew.h>
      #endif
    C
    assert_equal <<~C, pipe_output(bin/"cppi", test, 0)
      #ifdef TEST
      # include <homebrew.h>
      #endif
    C
  end
end
