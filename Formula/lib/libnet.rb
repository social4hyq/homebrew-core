class Libnet < Formula
  desc "C library for creating IP packets"
  homepage "https://github.com/libnet/libnet"
  url "https://github.com/libnet/libnet/releases/download/v1.3/libnet-1.3.tar.gz"
  sha256 "ad1e2dd9b500c58ee462acd839d0a0ea9a2b9248a1287840bc601e774fb6b28f"
  license "BSD-2-Clause"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3335a738979f470e1232cf6ffd593a02e142f4b61cbf550532c2e31f82ac1e95"
  end

  depends_on "doxygen" => :build
  depends_on "pkgconf" => :test

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdint.h>
      #include <libnet.h>

      int main(int argc, const char *argv[])
      {
        printf("%s", libnet_version());
        return 0;
      }
    C

    flags = shell_output("pkgconf --libs --cflags libnet").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    assert_match version.to_s, shell_output("./test")
  end
end
