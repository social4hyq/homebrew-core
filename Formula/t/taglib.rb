class Taglib < Formula
  desc "Audio metadata library"
  homepage "https://taglib.org/"
  url "https://taglib.github.io/releases/taglib-2.3.tar.gz"
  sha256 "7349f6fd942418bc7009ebe743eb7c9d055f02921ec56fa436ec25007c47fd38"
  license any_of: ["LGPL-2.1-only", "MPL-1.1"]
  compatibility_version 1
  head "https://github.com/taglib/taglib.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49c7c80d91961b0116eaba7465246d868ab2574beba81510d03c4620f2e75feb"
  end

  depends_on "cmake" => :build
  depends_on "utf8cpp"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %w[-DWITH_MP4=ON -DWITH_ASF=ON -DBUILD_SHARED_LIBS=ON]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <taglib/id3v2tag.h>
      #include <taglib/textidentificationframe.h>
      #include <iostream>

      int main() {
        TagLib::ID3v2::Tag tag;

        auto* artistFrame = new TagLib::ID3v2::TextIdentificationFrame("TPE1", TagLib::String::UTF8);
        artistFrame->setText("Test Artist");
        tag.addFrame(artistFrame);

        auto* titleFrame = new TagLib::ID3v2::TextIdentificationFrame("TIT2", TagLib::String::UTF8);
        titleFrame->setText("Test Title");
        tag.addFrame(titleFrame);

        std::cout << "Artist: " << tag.artist() << std::endl;
        std::cout << "Title: " << tag.title() << std::endl;

        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test", "-I#{include}", "-L#{lib}", "-ltag"
    assert_match "Artist: Test Artist", shell_output("./test")

    assert_match version.to_s, shell_output("#{bin}/taglib-config --version")
  end
end
