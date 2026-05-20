class Jrtplib < Formula
  desc "Fully featured C++ Library for RTP (Real-time Transport Protocol)"
  homepage "https://research.edm.uhasselt.be/jori/jrtplib"
  url "https://research.edm.uhasselt.be/jori/jrtplib/jrtplib-3.11.2.tar.bz2"
  sha256 "2c01924c1f157fb1a4616af5b9fb140acea39ab42bfb28ac28d654741601b04c"
  license "MIT"

  livecheck do
    skip "No longer developed"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a3d9007a0f70886b841d2421a9673738fcc1df36e940f90073394a17e1b1935e"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "jthread"

  def install
    # Workaround to build with CMake 4
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <jrtplib3/rtpsessionparams.h>
      using namespace jrtplib;
      int main() {
        RTPSessionParams sessionparams;
        sessionparams.SetOwnTimestampUnit(1.0/8000.0);
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-ljrtp",
                    "-o", "test"
    system "./test"
  end
end
