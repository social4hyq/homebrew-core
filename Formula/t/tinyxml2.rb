class Tinyxml2 < Formula
  desc "Improved tinyxml (in memory efficiency and size)"
  homepage "https://leethomason.github.io/tinyxml2/"
  url "https://github.com/leethomason/tinyxml2/archive/refs/tags/11.0.0.tar.gz"
  sha256 "5556deb5081fb246ee92afae73efd943c889cef0cafea92b0b82422d6a18f289"
  license "Zlib"
  revision 1
  compatibility_version 1
  head "https://github.com/leethomason/tinyxml2.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5fef045d0f7ef7623f420d5caedeefea8031ccfa23c5d8989bb9c95a17e33e51"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-Dtinyxml2_SHARED_LIBS=ON"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <tinyxml2.h>
      int main() {
        tinyxml2::XMLDocument doc (false);
        return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-L#{lib}", "-ltinyxml2", "-o", "test"
    system "./test"
  end
end
