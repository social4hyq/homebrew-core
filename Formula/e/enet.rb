class Enet < Formula
  desc "Provides a network communication layer on top of UDP"
  homepage "http://enet.bespin.org"
  url "https://cdn.netbsd.org/pub/pkgsrc/distfiles/enet-1.3.18.tar.gz"
  mirror "http://enet.bespin.org/download/enet-1.3.18.tar.gz"
  sha256 "2a8a0c5360d68bb4fcd11f2e4c47c69976e8d2c85b109dd7d60b1181a4f85d36"
  license "MIT"
  head "https://github.com/lsalzman/enet.git", branch: "master"

  livecheck do
    url "http://enet.bespin.org/Downloads.html"
    regex(/href=.*?enet[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8814af7f291b2409a34684ed9692642193e28c58ab2658f552c39eeafe0154a8"
  end

  def install
    system "./configure", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <enet/enet.h>
      #include <stdio.h>

      int main (int argc, char ** argv)
      {
        if (enet_initialize () != 0)
        {
          fprintf (stderr, "An error occurred while initializing ENet.\\n");
          return EXIT_FAILURE;
        }
        atexit (enet_deinitialize);
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lenet", "-o", "test"
    system testpath/"test"
  end
end
