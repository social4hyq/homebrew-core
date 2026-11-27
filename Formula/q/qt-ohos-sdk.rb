class QtOhosSdk < Formula
  desc "Qt 6.13 OHOS SDK with qtsvg, LinguistTools and Vulkan headers"
  homepage "https://gitcode.com/ohos-qt/qt-harmonyos-src"
  # gitcode serves SPA HTML for HTTP archive URLs; fetch the orphan release
  # branch at a fixed commit and extract the published SDK tarball from it.
  url "https://gitcode.com/ohos-qt/qt-harmonyos-src.git",
      revision: "03f4c83c02cee4a578d3caba30af86a9df812967"
  version "6.13.0-alpha1"
  license "LGPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "git" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  depends_on "zstd"

  # QtSvg is absent from the published SDK; build it from Qt sources with the
  # same toolchain (host and target are both aarch64-ohos in the CI container).
  resource "qtsvg" do
    url "https://github.com/qt/qtsvg/archive/1b86f8a4f30805932edc47ec9497c28769ee738e.tar.gz"
    sha256 "0ef5adba19ae0593164d7ee4e31a4d7bc26f255bf6cc40c3756557f2fb4c3552"
  end

  # Qt6LinguistTools macros plus lrelease/lupdate/lconvert (also absent from
  # the SDK). The host pass runs without a toolchain so the tools are native
  # OHOS ELFs; the CMake shim satisfies EXACT version requests.
  resource "qttools" do
    url "https://github.com/qt/qttools/archive/608d0878e0bc24985b19a1f11296a6a9b9c95c36.tar.gz"
    sha256 "fb6fc72f2c32d38ebfdc810965338d32aedb3715dbc34206425f2e66c248f776"
  end

  def install
    qt = libexec/"qt-6.13.0-dev"
    ohos_sdk = formula_opt_prefix("ohos-sdk")
    toolchain = ohos_sdk/"native/build/cmake/ohos.toolchain.cmake"

    tarball = buildpath.glob("*.tar.gz").first
    odie "Qt OHOS SDK tarball missing" unless tarball
    libexec.mkpath
    system "tar", "-xzf", tarball, "-C", libexec
    odie "Qt OHOS SDK layout changed" unless (qt/"lib/cmake/Qt6/Qt6Config.cmake").exist?

    # qmake in the SDK reports a <SDK>/lib prefix; override it.
    (qt/"bin/qt.conf").write "[Paths]\nPrefix=..\n"
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zstd")
    ENV.prepend_path "LD_LIBRARY_PATH", qt/"lib"

    resource("qtsvg").stage do
      system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
             "-DCMAKE_TOOLCHAIN_FILE=#{qt}/lib/cmake/Qt6/qt.toolchain.cmake",
             "-DQT_CHAINLOAD_TOOLCHAIN_FILE=#{toolchain}",
             "-DOHOS_ARCH=arm64-v8a", "-DQT_HOST_PATH=#{qt}",
             "-DCMAKE_PREFIX_PATH=#{qt}", *std_cmake_args(install_prefix: qt)
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    linguist = qt/"lib/cmake/Qt6LinguistTools"
    linguist.mkpath
    resource("qttools").stage do
      # Host pass: no cross toolchain, so CMake treats the OHOS target as host.
      system "cmake", "-S", ".", "-B", "host-build", "-G", "Ninja",
             "-DQT_QMAKE_TARGET_MKSPEC=ohos-clang",
             "-DCMAKE_EXE_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
             "-DCMAKE_BUILD_RPATH=$ORIGIN/../lib;#{formula_opt_lib("zstd")}",
             "-DFEATURE_designer=OFF", "-DFEATURE_assistant=OFF",
             "-DFEATURE_qdoc=OFF", "-DFEATURE_pixeltool=OFF",
             "-DCMAKE_PREFIX_PATH=#{qt}", *std_cmake_args
      system "cmake", "--build", "host-build", "--target", "lrelease", "lupdate", "lconvert"
      (qt/"libexec").install "host-build/bin/lrelease", "host-build/bin/lupdate", "host-build/bin/lconvert"
      %w[Qt6LinguistToolsMacros.cmake GenerateLUpdateProject.cmake].each do |name|
        cp "src/linguist/#{name}", linguist/name
      end
    end
    (linguist/"Qt6LinguistToolsConfig.cmake").write <<~CMAKE
      foreach(tool IN ITEMS lrelease lupdate lconvert)
        if(NOT TARGET Qt6::${tool})
          add_executable(Qt6::${tool} IMPORTED)
          set_target_properties(Qt6::${tool} PROPERTIES
            IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../libexec/${tool}")
        endif()
      endforeach()
      include("${CMAKE_CURRENT_LIST_DIR}/Qt6LinguistToolsMacros.cmake")
      set(Qt6LinguistTools_FOUND TRUE)
    CMAKE
    (linguist/"Qt6LinguistToolsConfigVersion.cmake").write <<~CMAKE
      set(PACKAGE_VERSION "6.13.0")
      if(PACKAGE_FIND_VERSION VERSION_LESS_EQUAL PACKAGE_VERSION)
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
      endif()
      if(PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
        set(PACKAGE_VERSION_EXACT TRUE)
      endif()
    CMAKE

    # QtGui links to system EGL/GLES which the NDK does not ship as dev stubs.
    gles = qt/"lib/cmake/Qt6GLESv3"
    gles.mkpath
    (gles/"FindGLESv3.cmake").write <<~CMAKE
      set(GLESv3_FOUND TRUE)
      if(NOT TARGET GLESv3::GLESv3)
        add_library(GLESv3::GLESv3 INTERFACE IMPORTED GLOBAL)
      endif()
    CMAKE

    # Vulkan headers exist in the sysroot but have no CMake config.
    shim = qt/"share/vk-shim/lib/cmake/VulkanHeaders"
    shim.mkpath
    (shim/"VulkanHeadersConfig.cmake").write <<~CMAKE
      set(VulkanHeaders_FOUND TRUE)
      if(NOT TARGET Vulkan::Headers)
        add_library(Vulkan::Headers INTERFACE IMPORTED GLOBAL)
        set_target_properties(Vulkan::Headers PROPERTIES
          INTERFACE_INCLUDE_DIRECTORIES "#{ohos_sdk}/native/sysroot/usr/include")
      endif()
    CMAKE
  end

  test do
    qt = libexec/"qt-6.13.0-dev"
    assert_path_exists qt/"lib/cmake/Qt6/Qt6Config.cmake"
    assert_path_exists qt/"lib/libQt6Svg.so"
    assert_path_exists qt/"share/vk-shim/lib/cmake/VulkanHeaders/VulkanHeadersConfig.cmake"
    system qt/"libexec/lrelease", "-version"
  end
end
