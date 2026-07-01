class Libupnp < Formula
  desc "Portable UPnP development kit"
  homepage "https://pupnp.sourceforge.io/"
  url "https://github.com/pupnp/pupnp/releases/download/release-2.0.2/libupnp-2.0.2.tar.bz2"
  sha256 "4a79edb812397e38b85bb95344a7fda4a17f54fbf53fdb828cc23ddb7e695f77"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^release[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d95fec013cfbb2e4f8dcae42736f8f8f7762526036466c9ae25c369341063c43"
  end

  def install
    # https://github.com/llvm/llvm-project/issues/65557
    inreplace "upnp/src/genlib/miniserver/miniserver.c", "switch (gMServState)",
                                                           "switch ((MiniServerState)gMServState)"

    system "./configure", "--enable-ipv6", *std_configure_args
    system "make", "install"
    pkgshare.install "upnp/test/test_init.c"
  end

  test do
    system ENV.cc, pkgshare/"test_init.c", "-o", "test", "-I#{include}/upnp", "-L#{lib}", "-lupnp"
    output = shell_output("./test")
    assert_match "UPNP_VERSION_STRING = \"#{version}\"", output
    assert_match "UPnP Initialized OK", output
  end
end
