class Openlibm < Formula
  desc "High quality, portable, open source libm implementation"
  homepage "https://openlibm.org"
  url "https://github.com/JuliaMath/openlibm/archive/refs/tags/v0.8.8.tar.gz"
  sha256 "721bab18ff37160fd9e903eb211ff26fdee38c3d0041d556b07d76089c435d17"
  license all_of: ["MIT", "ISC", "BSD-2-Clause"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7f0600a02702ef4a04efcfae9b5e50fe938b7120670d1115d9e94e4a6ad5f45"
  end

  def install
    lib.mkpath
    (lib/"pkgconfig").mkpath
    (include/"openlibm").mkpath

    system "make", "install", "prefix=#{prefix}"

    lib.install Dir["lib/*"].reject { |f| File.directory? f }
    (lib/"pkgconfig").install Dir["lib/pkgconfig/*"]
    (include/"openlibm").install Dir["include/openlibm/*"]
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "openlibm.h"
      int main (void) {
        printf("%.1f", cos(acos(0.0)));
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}/openlibm",
           "-o", "test"
    assert_equal "0.0", shell_output("./test")
  end
end
