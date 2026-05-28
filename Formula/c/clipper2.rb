class Clipper2 < Formula
  desc "Polygon clipping and offsetting library"
  homepage "https://github.com/AngusJohnson/Clipper2"
  url "https://github.com/AngusJohnson/Clipper2/releases/download/Clipper2_2.0.1/Clipper2_2.0.1.zip"
  sha256 "63e893fc40c3453c9d14cbe98bc7647f16a9d5846ae25b513d8a1ed5b8421144"
  license "BSL-1.0"

  livecheck do
    url :stable
    regex(/^Clipper2[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67a9df0f8adc6800c4548254ee536ba5166c56fba1df53281420d40d38edeb44"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DCLIPPER2_EXAMPLES=OFF
      -DCLIPPER2_TESTS=OFF
      -DBUILD_SHARED_LIBS=ON
    ]
    system "cmake", "-S", "CPP", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    inreplace "CPP/Examples/SimpleClipping/SimpleClipping.cpp" do |s|
      s.gsub! "\"../../Utils/clipper.svg.h\"", "\"clipper.svg.h\""
      s.gsub! "\"../../Utils/clipper.svg.utils.h\"", "\"clipper.svg.utils.h\""
    end

    pkgshare.install "CPP/Examples/SimpleClipping/SimpleClipping.cpp",
                     "CPP/Utils/clipper.svg.cpp",
                     "CPP/Utils/clipper.svg.h",
                     "CPP/Utils/clipper.svg.utils.h"
  end

  test do
    system ENV.cxx, pkgshare/"SimpleClipping.cpp", pkgshare/"clipper.svg.cpp",
                    "-std=c++17", "-I#{include}", "-L#{lib}", "-lClipper2",
                    "-o", "test"
    system "./test"
    refute_empty (testpath/"Intersect Paths.SVG").read
  end
end
