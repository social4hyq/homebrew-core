class Libetpan < Formula
  desc "Portable mail library handling several protocols"
  homepage "https://www.etpan.org/libetpan.html"
  url "https://github.com/dinhvh/libetpan/archive/refs/tags/1.10.tar.gz"
  sha256 "0ca9a79f66155e12156727856a40031030f5760f7bc88b29119e851b9c96e9eb"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/dinhvh/libetpan.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86a07880bca2720d5bc4445017e1077d3f832484b6edd07e4c374caf750c1b2d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  uses_from_macos "cyrus-sasl"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # autoconf 2.71+ probes -std=gnu23 first on modern compilers, which rejects K&R. Force gnu17.
    ENV.append "CFLAGS", "-std=gnu17"

    if OS.mac?
      # Keep macOS-native TLS (CFNetwork/Security) compiled in.
      ENV.append "CPPFLAGS", "-DHAVE_CFNETWORK=1"
      ENV.append "LDFLAGS", "-framework CoreFoundation -framework CoreServices -framework Security"
    end

    system "./autogen.sh", "--disable-db", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libetpan/libetpan.h>
      #include <string.h>
      #include <stdlib.h>

      int main(int argc, char ** argv)
      {
        printf("version is %d.%d",libetpan_get_version_major(), libetpan_get_version_minor());
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-letpan", "-o", "test"
    system "./test"
  end
end
