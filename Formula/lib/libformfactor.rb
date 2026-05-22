class Libformfactor < Formula
  desc "C++ library for the efficient computation of scattering form factors"
  homepage "https://jugit.fz-juelich.de/mlz/libformfactor"
  url "https://jugit.fz-juelich.de/mlz/libformfactor/-/archive/v0.4.0/libformfactor-v0.4.0.tar.bz2"
  sha256 "9e5f0458c78751121e0efa572f9a03e5965fe8ee2d4ff34939b6cce9bfdc8c36"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10707fa564da11ff8c3e1d02490467cc1a5a2779cfe0abb41aa20ef2d554b787"
  end

  depends_on "cmake" => :build
  depends_on "libheinz"

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DLibHeinz_DIR=#{Formula["libheinz"].opt_prefix}/cmake",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"fftest.cpp").write <<~CPP
      #include <ff/Face.h>
      #include <ff/Prism.h>
      #include <ff/Polyhedron.h>
      #include <cmath>  // abs

      bool CHECK_NEAR(const double value, const double expected, const double tol)
      {
        return std::abs(value - expected) <= tol;
      }

      bool test_asPolyhedron_prism()
      {
        ff::Prism prism(false, 1, {{-0.5, -0.5, 0}, {-0.5, 0.5, 0}, {0.5, 0.5, 0}, {0.5, -0.5, 0}});
        ff::Polyhedron* polyhedron = prism.asPolyhedron();

        const bool test0 = (polyhedron->faces().size() == 6);
        const bool test1 = CHECK_NEAR(polyhedron->vertices()[4].z(), 0.5, 1E-13);
        const bool test2 = CHECK_NEAR(polyhedron->vertices()[5].z(), 0.5, 1E-13);
        const bool test3 = CHECK_NEAR(polyhedron->vertices()[6].z(), 0.5, 1E-13);
        const bool test4 = CHECK_NEAR(polyhedron->vertices()[7].z(), 0.5, 1E-13);

        return test0 && test1 && test2 && test3 && test4;
      }

      bool test_faceCenter_CenteredRectangle()
      {
        // FaceCenter:CenteredRectangle
        ff::Face face({{-0.5, -1.4, 0}, {-0.5, 1.4, 0}, {0.5, 1.4, 0}, {0.5, -1.4, 0}}, true);
        const R3 center = face.center_of_polygon();
        const bool test1 = std::abs(center.x()) <= 1e-13;
        const bool test2 = std::abs(center.y()) <= 1e-13;
        const bool test3 = std::abs(center.z()) <= 1e-13;

        return test1 && test2 && test3;
      }

      int main()
      {
        const bool all_tests = test_asPolyhedron_prism() && test_faceCenter_CenteredRectangle();
        return all_tests? 0 : 1;
      }
    CPP

    system ENV.cxx, "-std=c++20", "fftest.cpp", "-I#{include}", "-L#{lib}", "-lformfactor", "-o", "fftest"
    system "./fftest"
  end
end
