class Gaul < Formula
  desc "Genetic Algorithm Utility Library"
  homepage "https://gaul.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/gaul/gaul-devel/0.1850-0/gaul-devel-0.1850-0.tar.gz"
  sha256 "7aabb5c1c218911054164c3fca4f5c5f0b9c8d9bab8b2273f48a3ff573da6570"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43690048c6b451c2b2dc7096a36c6372c5f9d8dcad3c68c51c30707099788a26"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    # Run autoreconf to regenerate the configure script and update outdated macros.
    # This ensures that the build system is properly configured on both macOS
    # (avoiding issues like flat namespace conflicts) and Linux (where outdated
    # config scripts may fail to detect the correct build type).
    system "autoreconf", "--force", "--verbose", "--install"
    system "./configure", "--disable-g", *std_configure_args
    system "make", "install"
  end

  test do
    resource "gaul-examples" do
      url "https://downloads.sourceforge.net/project/gaul/gaul-examples/0.1849/gaul-examples-0.1849-0.tar.bz2"
      sha256 "f4f59a0d676b0d58ba068424dfcb2c1715ff9aeaa940cab2daebff323274594c"
    end
    testpath.install resource("gaul-examples")

    system ENV.cc, "src/struggle.c", "-o", "test", "-L#{lib}", "-lgaul_util", "-lgaul"
    assert_match "The solution with seed = 49 was:\nWhen w^ yeil^ct%on%this strsggln,", shell_output("./test")
  end
end
