class UnittestCpp < Formula
  desc "Unit testing framework for C++"
  homepage "https://github.com/unittest-cpp/unittest-cpp"
  license "MIT"

  stable do
    url "https://github.com/unittest-cpp/unittest-cpp/releases/download/v2.0.0/unittest-cpp-2.0.0.tar.gz"
    sha256 "1d1b118518dc200e6b87bbf3ae7bfd00a0cfc6be708255f98e5e3d627a7c9f98"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7a8ddf543df916a97f755725883ae2bcadd3ee1d13bfe41e026f0d66641de15e"
  end

  head do
    url "https://github.com/unittest-cpp/unittest-cpp.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, File.read(lib/"pkgconfig/UnitTest++.pc")
  end
end
