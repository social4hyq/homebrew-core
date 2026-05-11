class Physfs < Formula
  desc "Library to provide abstract access to various archives"
  homepage "https://icculus.org/physfs/"
  url "https://github.com/icculus/physfs/archive/refs/tags/release-3.2.0.tar.gz"
  sha256 "1991500eaeb8d5325e3a8361847ff3bf8e03ec89252b7915e1f25b3f8ab5d560"
  license "Zlib"
  head "https://github.com/icculus/physfs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1263e7f129906d4eca348b5ec0f234b83ee8cab10d015cfe7263e5dd8d61d29"
  end

  depends_on "cmake" => :build

  uses_from_macos "zip" => :test

  on_linux do
    depends_on "readline"
  end

  def install
    # Workaround for CMake 4.0+. Remove on next release.
    if build.stable?
      odie "Remove CMake 4 workaround!" if version > "3.2.0"
      inreplace "CMakeLists.txt", "cmake_minimum_required(VERSION 3.0)",
                                  "cmake_minimum_required(VERSION 3.10)"
    end

    system "cmake", "-S", ".", "-B", "build",
                    "-DPHYSFS_BUILD_TEST=TRUE",
                    "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,#{rpath}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.txt").write "homebrew"
    system "zip", "test.zip", "test.txt"
    (testpath/"test").write <<~EOS
      addarchive test.zip 1
      cat test.txt
    EOS
    output = shell_output("#{bin}/test_physfs < test 2>&1")
    expected = if OS.mac?
      "Successful.\nhomebrew"
    else
      "Successful.\n> cat test.txt\nhomebrew"
    end
    assert_match expected, output
  end
end
