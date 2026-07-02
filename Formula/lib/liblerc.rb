class Liblerc < Formula
  desc "Esri LERC library (Limited Error Raster Compression)"
  homepage "https://github.com/Esri/lerc"
  url "https://github.com/Esri/lerc/archive/refs/tags/v4.1.1.tar.gz"
  sha256 "fe2860e10635166cd9f2144e429ec6b870d471e9957f5812ba2da0973770b022"
  license "Apache-2.0"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ef9514da2cae2dc2b477bf198f2d21cdc911223b079840296a2bb13495390a70"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <Lerc_c_api.h>
      #include <Lerc_types.h>
      int main() {
        const int infoArrSize = (int)LercNS::InfoArrOrder::_last;
        const int dataRangeArrSize = (int)LercNS::DataRangeArrOrder::_last;
        lerc_status hr(0);

        return 0 ;
      }
    CPP

    system ENV.cxx, "test.cc", "-std=gnu++17",
                    "-I#{include}",
                    "-L#{lib}",
                    "-lLerc",
                    "-o", "test_liblerc"

    assert_empty shell_output("./test_liblerc")
  end
end
