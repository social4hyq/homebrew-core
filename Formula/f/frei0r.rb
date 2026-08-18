class Frei0r < Formula
  desc "Minimalistic plugin API for video effects"
  homepage "https://frei0r.dyne.org/"
  url "https://github.com/dyne/frei0r/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "22ac75376236f75df6e2d17bb84ce366b93d80f01f9ac1c5b1810eefac940b3e"
  license "GPL-2.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8088c4bc8d40567a673e8305a31619187151621b011f1169ed91c79eda92b6dd"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DWITHOUT_OPENCV=ON
      -DWITHOUT_GAVL=ON
      -DWITHOUT_CAIRO=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <frei0r.h>

      int main()
      {
        int mver = FREI0R_MAJOR_VERSION;
        if (mver != 0) {
          return 0;
        } else {
          return 1;
        }
      }
    C
    system ENV.cc, "-L#{lib}", "test.c", "-o", "test"
    system "./test"
  end
end
