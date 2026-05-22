class Libsndfile < Formula
  desc "C library for files containing sampled sound"
  homepage "https://libsndfile.github.io/libsndfile/"
  url "https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz"
  sha256 "3799ca9924d3125038880367bf1468e53a1b7e3686a934f098b7e1d286cdb80e"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6b4de70860ef5d39dc1a7571b52bf0e74f836136614cb1be5e18a6ef7313851"
  end

  depends_on "cmake" => :build
  depends_on "flac"
  depends_on "lame"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "mpg123"
  depends_on "opus"

  uses_from_macos "python" => :build

  def install
    args = %W[
      -DBUILD_PROGRAMS=ON
      -DENABLE_PACKAGE_CONFIG=ON
      -DINSTALL_PKGCONFIG_MODULE=ON
      -DBUILD_EXAMPLES=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DPYTHON_EXECUTABLE=#{which("python3")}
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "static"
    lib.install "static/libsndfile.a"
  end

  test do
    output = shell_output("#{bin}/sndfile-info #{test_fixtures("test.wav")}")
    assert_match "Duration    : 00:00:00.064", output
  end
end
