class Clhep < Formula
  desc "Class Library for High Energy Physics"
  homepage "https://proj-clhep.web.cern.ch/proj-clhep/"
  url "https://gitlab.cern.ch/CLHEP/CLHEP/-/archive/CLHEP_2_4_7_2/CLHEP-CLHEP_2_4_7_2.tar.gz"
  sha256 "c40c239fa2c5810b60f4e9ddd6a8cc2ce81b962aa170994748cd2a2b5ac87f84"
  license "GPL-3.0-only"
  head "https://gitlab.cern.ch/CLHEP/CLHEP.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70c6df43830f261fc10d4d82a26e39250cc3fdb0e43a54cd13cc1ea34761869c"
  end

  depends_on "cmake" => :build

  def install
    # Build directory is not allowed inside source folder
    (buildpath/"CLHEP").install buildpath.children
    system "cmake", "-S", "CLHEP", "-B", "build", *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <Vector/ThreeVector.h>

      int main() {
        CLHEP::Hep3Vector aVec(1, 2, 3);
        std::cout << "r: " << aVec.mag();
        std::cout << " phi: " << aVec.phi();
        std::cout << " cos(theta): " << aVec.cosTheta() << std::endl;
        return 0;
      }
    CPP
    system ENV.cxx, "-std=c++11", "-L#{lib}", "-lCLHEP", "-I#{include}/CLHEP",
           testpath/"test.cpp", "-o", "test"
    assert_equal "r: 3.74166 phi: 1.10715 cos(theta): 0.801784",
                 shell_output("./test").chomp
  end
end
