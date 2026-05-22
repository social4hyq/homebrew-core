class Libcerf < Formula
  desc "Numeric library for complex error functions"
  homepage "https://jugit.fz-juelich.de/mlz/libcerf"
  url "https://jugit.fz-juelich.de/mlz/libcerf/-/archive/v3.3/libcerf-v3.3.tar.gz"
  sha256 "ea2910085448e269b5f0f0fabe51ffd846ac68881904be99669d94dc0cc09765"
  license "MIT"
  version_scheme 1
  compatibility_version 1
  head "https://jugit.fz-juelich.de/mlz/libcerf.git", branch: "main"

  livecheck do
    url "https://jugit.fz-juelich.de/api/v4/projects/269/releases"
    regex(/libcerf[._-]v?((?!2\.0)\d+(?:\.\d+)+)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f18c3b3e1aead9dbbdad804e119ccbd8a6ae94b39ac9543eeb65b3d0df4f30a7"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <cerf.h>
      #include <complex.h>
      #include <math.h>
      #include <stdio.h>
      #include <stdlib.h>

      int main (void) {
        double _Complex a = 1.0 - 0.4I;
        a = cerf(a);
        if (fabs(creal(a)-0.910867) > 1.e-6) abort();
        if (fabs(cimag(a)+0.156454) > 1.e-6) abort();
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcerf", "-o", "test"
    system "./test"
  end
end
