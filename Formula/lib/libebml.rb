class Libebml < Formula
  desc "Sort of a sbinary version of XML"
  homepage "https://www.matroska.org/"
  url "https://dl.matroska.org/downloads/libebml/libebml-1.4.5.tar.xz"
  sha256 "4971640b0592da29c2d426f303e137a9b0b3d07e1b81d069c1e56a2f49ab221b"
  license "LGPL-2.1-or-later"
  head "https://github.com/Matroska-Org/libebml.git", branch: "master"

  livecheck do
    url "https://dl.matroska.org/downloads/libebml/"
    regex(/href=.*?libebml[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ad20a85751358a0b3be4f4c95f20c317ae4f2b80f2a32e3472619384d4daf49"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <ebml/EbmlVoid.h>
      #include <iostream>

      int main() {
        libebml::EbmlVoid void_element;
        void_element.SetSize(1024);

        std::cout << "EbmlVoid element created with size: 1024" << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", "-I#{include}", "-L#{lib}", "-lebml"
    system "./test"
  end
end
