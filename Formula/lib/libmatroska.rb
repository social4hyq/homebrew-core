class Libmatroska < Formula
  desc "Extensible, open standard container format for audio/video"
  homepage "https://www.matroska.org/"
  url "https://dl.matroska.org/downloads/libmatroska/libmatroska-1.7.1.tar.xz"
  sha256 "572a3033b8d93d48a6a858e514abce4b2f7a946fe1f02cbfeca39bfd703018b3"
  license "LGPL-2.1-or-later"
  head "https://github.com/Matroska-Org/libmatroska.git", branch: "master"

  livecheck do
    url "https://dl.matroska.org/downloads/libmatroska/"
    regex(/href=.*?libmatroska[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2909e11245edb034da71a782d560a23fbd11c01b364a13dcd63258681386b0f0"
  end

  depends_on "cmake" => :build
  depends_on "libebml"

  def install
    if build.stable?
      odie "Remove `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`" if version > "1.7.1"
      args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    end

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <matroska/KaxVersion.h>
      #include <iostream>

      int main() {
        std::cout << "libmatroska version: " << libmatroska::KaxCodeVersion << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", "-I#{include}", "-L#{lib}", "-lmatroska"
    assert_match version.to_s, shell_output("./test")
  end
end
