class Zlib < Formula
  desc "General-purpose lossless data-compression library"
  homepage "https://zlib.net/"
  url "https://zlib.net/zlib-1.3.2.tar.gz"
  mirror "https://downloads.sourceforge.net/project/libpng/zlib/1.3.2/zlib-1.3.2.tar.gz"
  mirror "http://fresh-center.net/linux/misc/zlib-1.3.2.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/zlib-1.3.2.tar.gz"
  sha256 "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16"
  license "Zlib"
  revision 1
  head "https://github.com/madler/zlib.git", branch: "develop"

  livecheck do
    url :homepage
    regex(/href=.*?zlib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54a2a869296ac8572784483351c65ede1876cad5640184f6bb3f87529531fd0e"
  end

  keg_only :provided_by_macos

  on_linux do
    keg_only "it conflicts with zlib-ng-compat"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"

    # Avoid rebuilds of dependents that hardcode this path.
    inreplace lib/"pkgconfig/zlib.pc", prefix, opt_prefix
  end

  test do
    # https://zlib.net/zlib_how.html
    resource "zpipe.c" do
      url "https://raw.githubusercontent.com/madler/zlib/3f5d21e8f573a549ffc200e17dd95321db454aa1/examples/zpipe.c"
      mirror "http://zlib.net/zpipe.c"
      sha256 "e79717cefd20043fb78d730fd3b9d9cdf8f4642307fc001879dc82ddb468509f"
    end

    testpath.install resource("zpipe.c")
    system ENV.cc, "zpipe.c", "-I#{include}", "-L#{lib}", "-lz", "-o", "zpipe"

    text = "Hello, Homebrew!"
    compressed = pipe_output("./zpipe", text, 0)
    assert_equal text, pipe_output("./zpipe -d", compressed, 0)
  end
end
