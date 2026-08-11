class Libultrahdr < Formula
  desc "Reference codec for the Ultra HDR format"
  homepage "https://developer.android.com/media/platform/hdr-image-format"
  url "https://github.com/google/libultrahdr/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "588232d2c9adcd01541d48dc2e76f8448c52fea7fc2543e700a281b995ab50d2"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "73045cddb3aac73011db225174a656a8e55fa0555081f2b50b26e54741fd6b65"
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
