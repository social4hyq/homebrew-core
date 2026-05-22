class S2geometry < Formula
  desc "Computational geometry and spatial indexing on the sphere"
  homepage "https://github.com/google/s2geometry"
  url "https://github.com/google/s2geometry/archive/refs/tags/v0.14.0.tar.gz"
  sha256 "8c1f0a4b98472ed9df9807f5ec10ee57928cca388e16c13f430b652790d3ad8b"
  license "Apache-2.0"

  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "29203f93eab564404920ff96d07a76cf4ec94f75ff404e01ae847bb277e75568"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "abseil"

  def install
    # Keep C++ standard in sync with `abseil.rb`.
    args = %w[
      -DBUILD_TESTS=OFF
      -DCMAKE_CXX_STANDARD=17
    ]

    # Fix missing include of unaligned.h
    # Issue ref: https://github.com/google/s2geometry/issues/481
    inreplace "CMakeLists.txt", "src/s2/util/gtl/requires.h", "\\0 src/s2/util/gtl/unaligned.h"

    system "cmake", "-S", ".", "-B", "build/shared", *args, *std_cmake_args
    system "cmake", "--build", "build/shared"
    system "cmake", "--install", "build/shared"

    system "cmake", "-S", ".", "-B", "build/static", *args,
                    "-DBUILD_SHARED_LIBS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build/static"
    lib.install "build/static/libs2.a"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "s2/s2loop.h"
      #include "s2/s2polygon.h"
      #include "s2/s2latlng.h"

      #include <vector>
      #include <iostream>

      int main() {
          // Define the vertices of a polygon around a block near the Googleplex.
          std::vector<S2LatLng> lat_lngs = {
              S2LatLng::FromDegrees(37.422076, -122.084518),
              S2LatLng::FromDegrees(37.422003, -122.083984),
              S2LatLng::FromDegrees(37.421964, -122.084028),
              S2LatLng::FromDegrees(37.421847, -122.083171),
              S2LatLng::FromDegrees(37.422140, -122.083167),
              S2LatLng::FromDegrees(37.422076, -122.084518) // Last point equals the first one
          };

          std::vector<S2Point> points;
          for (const auto& ll : lat_lngs) {
              points.push_back(ll.ToPoint());
          }
          std::unique_ptr<S2Loop> loop = std::make_unique<S2Loop>(points);

          S2Polygon polygon(std::move(loop));

          S2LatLng test_point = S2LatLng::FromDegrees(37.422, -122.084);
          if (polygon.Contains(test_point.ToPoint())) {
              std::cout << "The point is inside the polygon." << std::endl;
          } else {
              std::cout << "The point is outside the polygon." << std::endl;
          }

          return 0;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test",
      "-L#{lib}", "-ls2", "-L#{Formula["abseil"].lib}", "-labsl_log_internal_message"
    system "./test"
  end
end
