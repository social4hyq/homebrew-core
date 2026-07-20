class Libebml < Formula
  desc "Sort of a sbinary version of XML"
  homepage "https://www.matroska.org/"
  url "https://dl.matroska.org/downloads/libebml/libebml-1.4.6.tar.xz"
  sha256 "d06cf1d5ad89390389eeb1eb7d50f70b55ac7538b19aeac8859eed3f2a9908dc"
  license "LGPL-2.1-or-later"
  head "https://github.com/Matroska-Org/libebml.git", branch: "master"

  livecheck do
    url "https://dl.matroska.org/downloads/libebml/"
    regex(/href=.*?libebml[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a00dfbeb57ee70cf52b870f6c9d63fe56bdc18638b8c2c167c503a05b6923a10"
  end

  depends_on "cmake" => :build
  depends_on "utf8cpp" => :build

  def install
    inreplace "CMakeLists.txt" do |s|
      # Allow to use newer utf8cpp library
      s.gsub! "find_package(utf8cpp 3.2.0)", "find_package(utf8cpp)"
      # https://github.com/Matroska-Org/libebml/issues/344
      s.gsub! "target_link_libraries(ebml PRIVATE $<BUILD_INTERFACE:utf8cpp>)", ""
    end

    ENV.append_to_cflags "-I#{formula_opt_include("utf8cpp")}/utf8cpp"

    args = %w[-DBUILD_SHARED_LIBS=ON]
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
