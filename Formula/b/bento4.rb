class Bento4 < Formula
  desc "Full-featured MP4 format and MPEG DASH library and tools"
  homepage "https://www.bento4.com/"
  url "https://www.bok.net/Bento4/source/Bento4-SRC-1-6-0-641.zip"
  version "1.6.0-641"
  sha256 "8258faf0de7253f2aac016018f33d4a04c16d9060735e14ec8711f84aaedf0c8"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://www.bok.net/Bento4/source/"
    regex(/href=.*?Bento4-SRC[._-]v?(\d+(?:[.-]\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ddf723f2822cfa82e744d369abda988322107132d438274f0066b9f4c27db29d"
  end

  depends_on "cmake" => :build
  depends_on "python@3.14"

  conflicts_with "mp4v2", because: "both install `mp4extract` and `mp4info` binaries"

  def install
    system "cmake", "-S", ".", "-B", "cmakebuild", "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.arch}", *std_cmake_args
    system "cmake", "--build", "cmakebuild"
    system "cmake", "--install", "cmakebuild"

    rm Dir["Source/Python/wrappers/*.bat"]
    inreplace Dir["Source/Python/wrappers/*"],
              "BASEDIR=$(dirname $0)", "BASEDIR=#{libexec}/Python/wrappers"
    libexec.install "Source/Python"
    bin.install_symlink Dir[libexec/"Python/wrappers/*"]
  end

  test do
    system bin/"mp4mux", "--track", test_fixtures("test.m4a"), "out.mp4"
    assert_path_exists testpath/"out.mp4", "Failed to create out.mp4!"
  end
end
