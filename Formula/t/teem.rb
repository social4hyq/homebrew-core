class Teem < Formula
  desc "Libraries for scientific raster data"
  homepage "https://teem.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/teem/teem/1.11.0/teem-1.11.0-src.tar.gz"
  sha256 "a01386021dfa802b3e7b4defced2f3c8235860d500c1fa2f347483775d4c8def"
  # License is LGPL-2.1-or-later with a non-SPDX license exception for linking
  license :cannot_represent
  head "https://svn.code.sf.net/p/teem/code/teem/trunk"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e7ef6ab2115e5194cb5b469fd958f2d3fff3d1335bf936d750d62cfa3fc3943"
  end

  depends_on "cmake" => :build
  depends_on "libpng"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fixes build with CMake 4.0+.
  patch :DATA

  def install
    # Installs CMake archive files directly into lib, which we discourage.
    # Workaround by adding version to libdir & then symlink into expected structure.
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DTeem_USE_LIB_INSTALL_SUBDIR=ON
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    lib.install_symlink Dir.glob(lib/"Teem-#{version}/#{shared_library("*")}")
    (lib/"cmake/teem").install_symlink Dir.glob(lib/"Teem-#{version}/*.cmake")
  end

  test do
    system bin/"nrrdSanity"
  end
end

__END__
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -413,7 +413,7 @@ ELSE(Teem_USE_LIB_INSTALL_SUBDIR)
   SET(EXTRA_INSTALL_PATH "")
 ENDIF(Teem_USE_LIB_INSTALL_SUBDIR)

-INSTALL(TARGETS teem
+INSTALL(TARGETS teem EXPORT teem-export
   RUNTIME DESTINATION bin
   LIBRARY DESTINATION lib${EXTRA_INSTALL_PATH}
   ARCHIVE DESTINATION lib${EXTRA_INSTALL_PATH}
@@ -448,7 +448,7 @@ ENDIF(BUILD_TESTING)
 #-----------------------------------------------------------------------------
 # Help outside projects build Teem projects.
 INCLUDE(CMakeExportBuildSettings)
-EXPORT_LIBRARY_DEPENDENCIES(${Teem_BINARY_DIR}/TeemLibraryDepends.cmake)
+install(EXPORT teem-export DESTINATION lib${EXTRA_INSTALL_PATH} FILE TeemLibraryDepends.cmake)
 CMAKE_EXPORT_BUILD_SETTINGS(${Teem_BINARY_DIR}/TeemBuildSettings.cmake)

 SET(CFLAGS "${CMAKE_C_FLAGS}")
@@ -512,6 +512,5 @@ INSTALL(FILES
   "${Teem_BINARY_DIR}/CMake/TeemConfig.cmake"
   "${Teem_SOURCE_DIR}/CMake/TeemUse.cmake"
   "${Teem_BINARY_DIR}/TeemBuildSettings.cmake"
-  "${Teem_BINARY_DIR}/TeemLibraryDepends.cmake"
   DESTINATION lib${EXTRA_INSTALL_PATH}
   )
