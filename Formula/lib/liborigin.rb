class Liborigin < Formula
  desc "Library for reading OriginLab OPJ project files"
  homepage "https://sourceforge.net/projects/liborigin/"
  url "https://downloads.sourceforge.net/project/liborigin/liborigin/3.0/liborigin-3.0.3.tar.gz"
  sha256 "b394e3bf633888f9f4a3e1449d7c7eb39b778a2e657424177a04cde4afe6965a"
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later"]

  livecheck do
    url :stable
    regex(%r{url=.*?/liborigin[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cefdba87c070eefea527884cda103110f8cc6e8e44f8656054c9c2e45d44d5f8"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <liborigin/OriginFile.h>

      int main() {
          std::cout << "liborigin version: " << liboriginVersionString() << std::endl;
          return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-lorigin", "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
