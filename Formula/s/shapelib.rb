class Shapelib < Formula
  desc "Library for reading and writing ArcView Shapefiles"
  homepage "http://shapelib.maptools.org/"
  url "https://download.osgeo.org/shapelib/shapelib-1.6.3.tar.gz"
  sha256 "3ff5ead18ca6d2fe249f0e80b361e1ad6782165115268ed4a58c780a60c1e0eb"
  license any_of: ["LGPL-2.0-or-later", "MIT"]

  livecheck do
    url "https://download.osgeo.org/shapelib/"
    regex(/href=.*?shapelib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3595baf05be15a0318e5881ae6464dd75ee18a9e6809c99cbd78a9091101c755"
  end

  depends_on "cmake" => :build

  def install
    # shapelib's CMake scripts interpret `CMAKE_INSTALL_LIBDIR=lib` as relative
    # to the current directory, i.e. `CMAKE_INSTALL_LIBDIR:PATH=$(pwd)/lib`
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args(install_libdir: lib)
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match "shp_file", shell_output("#{bin}/shptreedump", 1)
  end
end
