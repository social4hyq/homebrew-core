class Soci < Formula
  desc "Database access library for C++"
  homepage "https://soci.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/soci/soci/soci-4.1.3/soci-4.1.3.zip"
  sha256 "2760b6d4007a5fbfdd9c1fc00854dd39c430aacc201786fb01680a55311d6585"
  license "BSL-1.0"

  livecheck do
    url :stable
    regex(%r{url=.*?/soci[._-]v?(\d+(?:\.\d+)+)\.zip}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "395a7ba888d09500aa3504b54fff13476fa5a8760bc97c22087412df0935d59e"
  end

  depends_on "cmake" => :build
  depends_on "sqlite"

  def install
    args = %W[
      -DCMAKE_CXX_STANDARD=14
      -DSOCI_TESTS=OFF
      -DWITH_SQLITE3=ON
      -DWITH_BOOST=OFF
      -DWITH_MYSQL=OFF
      -DWITH_ODBC=OFF
      -DWITH_ORACLE=OFF
      -DWITH_POSTGRESQL=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cxx").write <<~CPP
      #include "soci/soci.h"
      #include "soci/empty/soci-empty.h"
      #include <string>

      using namespace soci;
      std::string connectString = "";
      backend_factory const &backEnd = *soci::factory_empty();

      int main(int argc, char* argv[])
      {
        soci::session sql(backEnd, connectString);
      }
    CPP
    system ENV.cxx, "-o", "test", "test.cxx", "-std=c++14", "-L#{lib}", "-lsoci_core", "-lsoci_empty"
    system "./test"
  end
end
