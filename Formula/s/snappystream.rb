class Snappystream < Formula
  desc "C++ snappy stream realization (compatible with snappy)"
  homepage "https://github.com/hoxnox/snappystream"
  url "https://github.com/hoxnox/snappystream/archive/refs/tags/1.0.0.tar.gz"
  sha256 "a50a1765eac1999bf42d0afd46d8704e8c4040b6e6c05dcfdffae6dcd5c6c6b8"
  license "Apache-2.0"
  revision 1
  head "https://github.com/hoxnox/snappystream.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22b0310927552f8bcb8e7bd87b12979ebdb5b40713298ef1fc55693f8d45b3a8"
  end

  depends_on "cmake" => :build
  depends_on "snappy"

  def install
    args = %w[
      -DBUILD_TESTS=ON
      -DCMAKE_CXX_STANDARD=11
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cxx").write <<~CPP
      #include <iostream>
      #include <fstream>
      #include <iterator>
      #include <algorithm>
      #include <snappystream.hpp>

      int main()
      {
        { std::ofstream ofile("snappy-file.dat");
          snappy::oSnappyStream osnstrm(ofile);
          std::cin >> std::noskipws;
          std::copy(std::istream_iterator<char>(std::cin), std::istream_iterator<char>(), std::ostream_iterator<char>(osnstrm));
        }
        { std::ifstream ifile("snappy-file.dat");
          snappy::iSnappyStream isnstrm(ifile);
          isnstrm >> std::noskipws;
          std::copy(std::istream_iterator<char>(isnstrm), std::istream_iterator<char>(), std::ostream_iterator<char>(std::cout));
        }
      }
    CPP
    system ENV.cxx, "test.cxx", "-o", "test",
                    "-L#{lib}", "-lsnappystream",
                    "-L#{Formula["snappy"].opt_lib}", "-lsnappy"
    system "./test < #{__FILE__} > out.dat && diff #{__FILE__} out.dat"
  end
end
