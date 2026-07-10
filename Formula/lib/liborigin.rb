class Liborigin < Formula
  desc "Library for reading OriginLab OPJ project files"
  homepage "https://sourceforge.net/projects/liborigin/"
  url "https://downloads.sourceforge.net/project/liborigin/liborigin/3.0/liborigin-3.0.4.tar.gz"
  sha256 "b1bf35f72e39892ad351bed4a3e724aee6cfa673281dea2c78cceb9042a74e57"
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later"]

  livecheck do
    url :stable
    regex(%r{url=.*?/liborigin[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f5ad10f0fee5d2043122f64f1a50576181c0ecccb7053b7f62019426c13eabe7"
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
