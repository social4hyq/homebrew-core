class Cmockery2 < Formula
  desc "Reviving cmockery unit test framework from Google"
  homepage "https://github.com/lpabon/cmockery2"
  url "https://github.com/lpabon/cmockery2/archive/refs/tags/v1.3.9.tar.gz"
  sha256 "c38054768712351102024afdff037143b4392e1e313bdabb9380cab554f9dbf2"
  license "Apache-2.0"
  head "https://github.com/lpabon/cmockery2.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1212dc1781a05a56cab2b0bceee50e72dbaf33e6c08727615ae51c9b2e0b934"
  end

  # last commit was 7 years ago, cmockery is also deprecated
  deprecate! date: "2024-07-07", because: :unmaintained
  disable! date: "2025-07-07", because: :unmaintained

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
    (share/"example").install "src/example/calculator.c"
  end

  test do
    system ENV.cc, share/"example/calculator.c", "-L#{lib}", "-lcmockery", "-o", "calculator"
    system "./calculator"
  end
end
