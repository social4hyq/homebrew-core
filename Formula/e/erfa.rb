class Erfa < Formula
  desc "Essential Routines for Fundamental Astronomy"
  homepage "https://github.com/liberfa/erfa"
  url "https://github.com/liberfa/erfa/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "d5469fbd0b212b3c7270c1da15c9bd82f37da9218fc89627f98283d27b416cbf"
  license "BSD-3-Clause"
  head "https://github.com/liberfa/erfa.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a5b67a96dc541c32d5f8235d98b2b85fc1b049766205b3d5b2b95b84fd8da3a"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <erfa.h>
      #include <erfaextra.h>
      #include <stdio.h>
      #include <string.h>
      int main() {
        /* Test version functions */
        char buf[16];
        sprintf(buf, "%d.%d.%d", eraVersionMajor(), eraVersionMinor(), eraVersionMicro());
        if (strcmp(buf, "#{version}") != 0) {
          printf("Version mismatch: expected #{version}, got %s\\n", buf);
          return 1;
        }

        /* Test calculation (Degrees to Degrees, Minutes, Seconds) */
        int idmsf[4];
        char s;
        eraA2af(4, 2.345, &s, idmsf);
        if (s != '+' || idmsf[0] != 134 || idmsf[1] != 21 || idmsf[2] != 30 || idmsf[3] != 9706) {
          return 1;
        }

        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lerfa", "-o", "test"
    system "./test"
  end
end
