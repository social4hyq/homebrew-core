class Libwebm < Formula
  desc "WebM container"
  homepage "https://www.webmproject.org/code/"
  url "https://github.com/webmproject/libwebm/archive/refs/tags/libwebm-1.0.0.32.tar.gz"
  sha256 "7fd5e085bda9f8031cf2ad2a1e52d9b7b29cba9c0b96ad2ce794ce89e4249eb8"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67ee9761b97c0abd783d5f3642c315b5f70da6d383ee4bbc8c6973064aab5d71"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    lib.install "build/libwebm.a"
    bin.install Dir["build/{mkvparser_sample,mkvmuxer_sample,vttdemux,webm2pes}"]

    include.install Dir.glob("mkv*.hpp")
    (include/"mkvmuxer").install Dir.glob("mkvmuxer/mkv*.h")
    (include/"common").install Dir.glob("common/*.h")
    (include/"mkvparser").install Dir.glob("mkvparser/mkv*.h")
    include.install Dir.glob("vtt*.h")
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <mkvwriter.hpp>
      #include <iostream>

      int main() {
        mkvmuxer::MkvWriter writer;

        std::string test_mkv = "#{testpath}/test.mkv";

        if (!writer.Open(test_mkv.c_str())) {
          std::cerr << "Failed to open the MKV file." << std::endl;
          return 1;
        }

        writer.Close();
        std::cout << "MkvWriter test completed successfully." << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", "-I#{include}", "-L#{lib}", "-lwebm"
    system "./test"
    assert_path_exists testpath/"test.mkv"
  end
end
