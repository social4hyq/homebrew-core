class Jasper < Formula
  desc "Library for manipulating JPEG-2000 images"
  homepage "https://ece.engr.uvic.ca/~frodo/jasper/"
  url "https://github.com/jasper-software/jasper/releases/download/version-4.2.9/jasper-4.2.9.tar.gz"
  sha256 "f71cf643937a5fcaedcfeb30a22ba406912948ad4413148214df280afc425454"
  license "JasPer-2.0"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^version[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d182dc436e8d602410fef1f01ec96e410346ecca015e57c79b334847ae3503f7"
  end

  depends_on "cmake" => :build
  depends_on "jpeg-turbo"

  # OHOS: tmpfile() is broken (returns ENOENT). Use jpeg_mem_src() instead.
  patch do
    file "Patches/jasper/0001-replace-tmpfile-with-jpeg-mem-src.patch"
  end

  def install
    args = %W[
      -DJAS_ENABLE_DOC=OFF
      -DJAS_ENABLE_AUTOMATIC_DEPENDENCIES=OFF
      -DJAS_ENABLE_OPENGL=OFF
    ]

    # Build shared library.
    system "cmake", "-S", ".", "-B", "../build-shared", "-DJAS_ENABLE_SHARED=ON", *args, *std_cmake_args
    system "cmake", "--build", "../build-shared"
    system "cmake", "--install", "../build-shared"

    # Build static library.
    system "cmake", "-S", ".", "-B", "../build-static", "-DJAS_ENABLE_SHARED=OFF", *args, *std_cmake_args
    system "cmake", "--build", "../build-static"
    lib.install "../build-static/src/libjasper/libjasper.a"

    # Move the build directories into `buildpath` so Homebrew captures log files properly.
    buildpath.install ["../build-shared", "../build-static"]

    # Avoid rebuilding dependents that hard-code the prefix.
    inreplace lib/"pkgconfig/jasper.pc", prefix, opt_prefix
  end

  test do
    system bin/"jasper", "--input", test_fixtures("test.jpg"),
                         "--output", "test.bmp"
    assert_path_exists testpath/"test.bmp"
  end
end
