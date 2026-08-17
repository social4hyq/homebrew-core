class Libultrahdr < Formula
  desc "Reference codec for the Ultra HDR format"
  homepage "https://developer.android.com/media/platform/hdr-image-format"
  url "https://github.com/google/libultrahdr/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "aa8d193bb887c348c419780511dd03b374f4e07af8812b6d3f80c8537cf1ef2c"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4bb6b5c4e1e7d0beb03945f818599ab7cf931bb3cc4953ee0da3eba3d35013e8"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test
  depends_on "jpeg-turbo"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <ultrahdr_api.h>
      #include <iostream>

      int main() {
        std::cout << "UltraHDR Library Version: " << UHDR_LIB_VERSION_STR << std::endl;

        uhdr_codec_private_t* encoder = uhdr_create_encoder();
        uhdr_release_encoder(encoder);

        return 0;
      }
    CPP

    pkg_config_cflags = shell_output("pkg-config --cflags --libs libuhdr").chomp.split
    system ENV.cxx, "test.cpp", "-o", "test", "-o", "test", *pkg_config_cflags
    assert_match "UltraHDR Library Version: #{version}", shell_output("./test")
  end
end
