class SnowShotApp < Formula
  desc "Screenshot and annotation utility from Snow Apps, unsigned OHOS HAP"
  homepage "https://github.com/mg-chao/snow-shot"
  url "https://github.com/mg-chao/snow-shot/archive/refs/tags/v1.5.7_snow-shot.tar.gz"
  sha256 "6d9de662710ccf406dea312c0322e77a3f473bc6121096ec82df713d30f4273c"
  license "GPL-3.0-or-later"
  revision 20

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/snow-shot-app-v1.5.7-r7"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "73201417666e10f1f508fece6b51787c61ac7ff800c98ec3922806af6fc1e0be"
  end

  depends_on "brotli" => :build
  depends_on "bzip2" => :build
  depends_on "cmake" => :build
  depends_on "expat" => :build
  depends_on "ffmpeg" => :build
  depends_on "fontconfig" => :build
  depends_on "freetype" => :build
  depends_on "gettext" => :build
  depends_on "giflib" => :build
  depends_on "highway" => :build
  depends_on "imath" => :build
  depends_on "jpeg-turbo" => :build
  depends_on "jpeg-xl" => :build
  depends_on "libheif" => :build
  depends_on "libpng" => :build
  depends_on "libtiff" => :build
  depends_on "little-cms2" => :build
  depends_on "lunasvg" => :build
  depends_on "minizip-ng" => :build
  depends_on "ninja" => :build
  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "openexr" => :build
  depends_on "openssl@4" => :build
  depends_on "patchelf" => :build
  depends_on "pkgconf" => :build
  depends_on "plutovg" => :build
  depends_on "rust" => :build
  depends_on "snow-shot-opencv" => :build
  depends_on "tinyxml2" => :build
  depends_on "webp" => :build
  depends_on "zlib-ng-compat" => :build
  depends_on "zstd" => :build
  depends_on "app-installer"
  depends_on "ohos-sdk-toolchains"

  resource "ocr-detection-model" do
    url "https://www.modelscope.cn/models/mgchao/SnowShotOCR/resolve/master/PP-OCRv6/small/PP-OCRv6_det_small.onnx"
    sha256 "090f04abcd9d9a7498bc4ebf677e4cb9bdce1fe4197ddb7e529f1ef44e1ff94f"
  end

  resource "ocr-recognition-model" do
    url "https://www.modelscope.cn/models/mgchao/SnowShotOCR/resolve/master/PP-OCRv6/small/PP-OCRv6_rec_small.onnx"
    sha256 "6f327246b50388f3c176ae304bd95767ea6dc0c9ae92153ef8cbe210b3c14884"
  end

  resource "ocr-dictionary" do
    url "https://www.modelscope.cn/models/mgchao/SnowShotOCR/resolve/master/PP-OCRv6/small/ppocrv6_dict.txt"
    sha256 "b5f2bfe2bdd9448429e3e82b51c789775d9b42f2403d082b00662eb77e401c5d"
  end

  resource "snow-shot-ocr-rs" do
    url "https://github.com/mg-chao/simd-paddle-ocr-rs/archive/43aba513b661e48eacb04d19f1ff071649116ddf.tar.gz"
    sha256 "73072343793760861059d363f24596ee72c47e46dcfe2adf8e1004f3a2b4f1f0"

    patch do
      file "Patches/snow-shot-app/ocr/src_runtime.rs.patch"
    end
  end

  resource "qr-model-assets" do
    url "https://github.com/WeChatCV/opencv_3rdparty/archive/a8b69ccc738421293254aec5ddb38bd523503252.tar.gz"
    sha256 "7a16ad6ca511c620c2a4cbef2c7cf1ff5c31bd530ac7b43ee2ea8481683df20a"
  end

  resource "qttranslations" do
    url "https://github.com/qt/qttranslations/archive/ef8d82535484b38a616ff3fb96510172772b85c5.tar.gz"
    sha256 "98a8e2bcde16cff31440db848b2739312c2a2f55fe5174e9a5d5fc0f9a6230af"
  end

  resource "microtex" do
    url "https://github.com/NanoMichael/MicroTeX/archive/0e3707f6dafebb121d98b53c64364d16fefe481d.tar.gz"
    sha256 "47476269d29c41df322bce6bdd2daa7017cc50b9eda841b2bec1767dba28daa6"
  end

  resource "qttools" do
    url "https://github.com/qt/qttools/archive/0768385eee6344768c1312821ae7124f7498aa6a.tar.gz"
    sha256 "0100cea754381ef5839e1565f4f96e328cc3014b75103b4e0d268102e420c29a"
  end

  resource "jthread" do
    url "https://github.com/josuttis/jthread/archive/0fa8d394254886c555d6faccd0a3de819b7d47f8.tar.gz"
    sha256 "d3a20e0c1b2758c4545b0a97490afa2986e39c8b4387c3dba2007def742cbeb0"
  end

  # The Qt SDK ships a QtNetwork configured with -no-openssl, so QSslSocket does
  # not exist at all and every https request fails. Rebuild the same qtbase
  # snapshot with the runtime OpenSSL backend and ship the replacement library
  # together with its TLS plugin.
  resource "qtbase" do
    url "https://github.com/qt/qtbase/archive/45a213e8d07f3823148ee59481e2fe3d7f4ef2df.tar.gz"
    sha256 "b2c167f8f32e5b0ae5347ff368ad2a39edf45a7d72162ac6baf4a4554d3afad3"
  end

  # QtCore/Network need the NAPI headers of the OpenHarmony platform layer.
  resource "node-addon-api" do
    url "https://github.com/nodejs/node-addon-api/archive/refs/tags/v8.9.2.tar.gz"
    sha256 "762e7b50e05b21017776add0811b8bca184276332a7716ad631fea6d3421e269"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/snow-shot-app/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # Tap-authored HAP template, staging scripts and launcher. They are not
  # patches, so they live in Resources/ rather than Patches/. Every path is
  # listed literally: the weekly remove-unused-patches job keeps a Resources/
  # directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/snow-shot-app/ohos-template/AppScope/resources/base/media/app_icon.png
    Resources/snow-shot-app/ohos-template/assets/README.md
    Resources/snow-shot-app/ohos-template/assets/app-icon.svg
    Resources/snow-shot-app/ohos-template/assets/app-labels.json
    Resources/snow-shot-app/ohos-template/entry/src/main/cpp/types/libsnow_shot/index.d.ts
    Resources/snow-shot-app/ohos-template/entry/src/main/ets/qability/QAbility.ets
    Resources/snow-shot-app/ohos-template/entry/src/main/ets/statusbar/StatusBarAbility.ets
    Resources/snow-shot-app/ohos-template/entry/src/main/ets/statusbar/StatusBarPage.ets
    Resources/snow-shot-app/ohos-template/entry/src/main/resources/base/media/background.png
    Resources/snow-shot-app/ohos-template/entry/src/main/resources/base/media/foreground.png
    Resources/snow-shot-app/ohos-template/entry/src/main/resources/base/media/startIcon.png
    Resources/snow-shot-app/snow-shot-install.sh
    Resources/snow-shot-app/support/scripts/add-ohos-module-permissions.py
    Resources/snow-shot-app/support/scripts/finalize-ohos-ocr-manifest.py
    Resources/snow-shot-app/support/scripts/stage-ohos-app-icon-assets.py
    Resources/snow-shot-app/support/scripts/stage-ohos-app-label-assets.py
    Resources/snow-shot-app/support/scripts/stage-ohos-ocr-assets.py
    Resources/snow-shot-app/support/scripts/test-add-ohos-module-permissions.py
    Resources/snow-shot-app/support/scripts/test-finalize-ohos-ocr-manifest.py
    Resources/snow-shot-app/support/scripts/test-snow-shot-hap-runtime-closure.py
    Resources/snow-shot-app/support/scripts/test-stage-ohos-ocr-assets.py
  ].freeze

  def install
    qt = Pathname.new("/opt/qt-ohos/qt-6.13.0-dev")
    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "snow-shot builds only in the qt-ohos-ci CI image" unless (qt/"lib/cmake/Qt6/Qt6Config.cmake").exist?

    ohos_sdk = formula_opt_prefix("ohos-sdk")
    opencv = formula_opt_prefix("snow-shot-opencv")
    ENV.prepend_path "PATH", ohos_sdk/"native/llvm/bin"
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@4").to_s
    ENV["LD_LIBRARY_PATH"] = [
      "#{qt}/lib", "#{clt}/lib",
      "#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos",
      "#{opencv}/lib", "#{formula_opt_prefix("zstd")}/lib"
    ].join(":")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    ocr_crate = buildpath/"snow-crates/crates/simd-paddle-ocr-rs"
    resource("jthread").stage buildpath/"jthread"
    mkdir_p ocr_crate
    tap_root = Pathname(__FILE__).parent.parent.parent
    res = tap_root/"Resources/snow-shot-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end
    resource("snow-shot-ocr-rs").stage do
      cp_r ".", ocr_crate
    end
    %w[ocr-detection-model ocr-recognition-model ocr-dictionary].each do |name|
      resource(name).stage do
        model_dir = buildpath/"ocr-models/ppocrv6-small-463ea9f"
        mkdir_p model_dir
        filename = Dir.children(".").first
        cp filename, model_dir/filename
      end
    end
    qt_translation_dir = buildpath/"qt-translations"
    mkdir_p qt_translation_dir
    resource("qttranslations").stage do
      source = Pathname.new(".")
      unless (source/"translations/qtbase_zh_CN.ts").file?
        source = Dir.children(".").map { |entry| Pathname.new(entry) }
                    .find { |entry| entry.directory? && (entry/"translations/qtbase_zh_CN.ts").file? }
      end
      odie "could not find Qt base translation catalogs" unless source
      %w[zh_CN zh_TW].each do |locale|
        system qt/"libexec/lrelease", source/"translations/qtbase_#{locale}.ts",
               "-qm", qt_translation_dir/"qtbase_#{locale}.qm"
      end
    end
    microtex_source_dir = buildpath/"microtex-source"
    mkdir_p microtex_source_dir
    resource("microtex").stage do
      source = Pathname.new(".")
      unless (source/"src").directory?
        source = Dir.children(".").map { |entry| Pathname.new(entry) }
                    .find { |entry| entry.directory? && (entry/"src").directory? }
      end
      odie "could not find MicroTeX source root" unless source
      cp_r source.children, microtex_source_dir
    end
    qr_root = buildpath/"artifacts/qr-models-wechat"
    mkdir_p qr_root
    resource("qr-model-assets").stage do
      qr_source = if (Pathname.new(".")/"detect.prototxt").file?
        Pathname.new(".")
      else
        Dir.children(".").map { |entry| Pathname.new(entry) }
           .find { |entry| entry.directory? && (entry/"detect.prototxt").file? }
      end
      odie "could not find the WeChat QR model root" unless qr_source
      %w[detect.prototxt detect.caffemodel sr.prototxt sr.caffemodel].each do |filename|
        cp qr_source/filename, qr_root/filename
      end
    end

    # Rebuild QtNetwork with OpenSSL before the application build and keep only
    # its two payload files; the application itself keeps linking against the
    # SSL-less SDK copy. Building it first also frees the Qt build tree before
    # the much larger application build needs the disk.
    qt_tls = build_qt_tls(qt, ohos_sdk)

    zlib_ng = formula_opt_prefix("zlib-ng-compat")
    qt_module_path = buildpath/"cmake/qt-modules"
    vulkan_include = buildpath/"vulkan-headers/include"
    mkdir_p vulkan_include
    %w[vulkan vk_video].each do |name|
      source = ohos_sdk/"native/sysroot/usr/include"/name
      cp_r source, vulkan_include/name if source.directory?
    end
    mkdir_p qt_module_path
    (qt_module_path/"FindGLESv3.cmake").write <<~CMAKE
      # QtGui links to OpenHarmony system EGL/GLES libraries that are not shipped
      # as NDK development stubs in the private build image.
      set(GLESv3_FOUND TRUE)
      if(NOT TARGET GLESv3::GLESv3)
        add_library(GLESv3::GLESv3 INTERFACE IMPORTED GLOBAL)
      endif()
    CMAKE
    qt_component_args = Dir.glob(qt/"lib/cmake/Qt6*").filter_map do |config_dir|
      "-D#{Pathname.new(config_dir).basename}_DIR=#{config_dir}" if Pathname.new(config_dir).directory?
    end
    linguist_cmake = buildpath/"cmake/Qt6LinguistTools"
    mkdir_p linguist_cmake
    resource("qttools").stage do
      source = Pathname.new(".")
      unless (source/"src/linguist/Qt6LinguistToolsMacros.cmake").file?
        source = Dir.children(".").map { |entry| Pathname.new(entry) }
                    .find { |entry| (entry/"src/linguist/Qt6LinguistToolsMacros.cmake").file? }
      end
      odie "could not find Qt LinguistTools macros" unless source
      %w[Qt6LinguistToolsMacros.cmake GenerateLUpdateProject.cmake].each do |name|
        cp source/"src/linguist"/name, linguist_cmake/name
      end
    end
    cp qt/"lib/cmake/Qt6LinguistTools/Qt6LinguistToolsConfigVersion.cmake", linguist_cmake
    (linguist_cmake/"Qt6LinguistToolsConfig.cmake").write <<~CMAKE
      include("#{qt}/lib/cmake/Qt6LinguistTools/Qt6LinguistToolsConfig.cmake")
      set(_Qt6_LINGUIST_TOOLS_DIR "${CMAKE_CURRENT_LIST_DIR}")
      include("${CMAKE_CURRENT_LIST_DIR}/Qt6LinguistToolsMacros.cmake")
    CMAKE
    lcms2_cmake = buildpath/"cmake/lcms2"
    mkdir_p lcms2_cmake
    (lcms2_cmake/"lcms2Config.cmake").write <<~CMAKE
      if(NOT TARGET lcms2::lcms2)
        add_library(lcms2::lcms2 UNKNOWN IMPORTED)
        set_target_properties(lcms2::lcms2 PROPERTIES
          IMPORTED_LOCATION "#{formula_opt_prefix("little-cms2")}/lib/liblcms2.so"
          INTERFACE_INCLUDE_DIRECTORIES "#{formula_opt_prefix("little-cms2")}/include"
        )
      endif()
    CMAKE
    libheif_cmake = buildpath/"cmake/libheif"
    mkdir_p libheif_cmake
    (libheif_cmake/"libheifConfig.cmake").write <<~CMAKE
      if(NOT TARGET heif)
        add_library(heif UNKNOWN IMPORTED)
        set_target_properties(heif PROPERTIES
          IMPORTED_LOCATION "#{formula_opt_lib("libheif")}/libheif.so"
          INTERFACE_INCLUDE_DIRECTORIES "#{formula_opt_include("libheif")}"
        )
      endif()
    CMAKE
    cmake_prefix_path = ([qt, opencv] + recursive_dependencies.filter_map do |dependency|
      prefix = dependency.to_formula.opt_prefix
      prefix if prefix.directory?
    end).uniq.join(";")
    system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
           *qt_component_args,
           "-DQt6LinguistTools_DIR=#{linguist_cmake}",
           "-DCMAKE_MODULE_PATH=#{qt_module_path}",
           "-DCMAKE_TOOLCHAIN_FILE=#{qt}/lib/cmake/Qt6/qt.toolchain.cmake",
           "-DCMAKE_MAKE_PROGRAM=#{formula_opt_prefix("ninja")}/bin/ninja",
           "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON",
           "-DQT_INTERNAL_ABSOLUTE_TRANSLATIONS_DIR=#{qt_translation_dir}",
           "-DFETCHCONTENT_SOURCE_DIR_SNOW_MICROTEX_SOURCE=#{microtex_source_dir}",
           "-DQT_CHAINLOAD_TOOLCHAIN_FILE=#{ohos_sdk}/native/build/cmake/ohos.toolchain.cmake",
           "-DOHOS_ARCH=arm64-v8a",
           "-DSNOW_FFMPEG_ROOT=#{formula_opt_prefix("ffmpeg")}",
           "-DVulkanHeaders_DIR=/opt/qt-ohos/vk-shim/lib/cmake/VulkanHeaders",
           "-DVulkan_INCLUDE_DIR=#{vulkan_include}",
           "-DOpenCV_DIR=#{opencv}/lib/cmake/opencv4",
           "-Dlcms2_DIR=#{lcms2_cmake}",
           "-Dlibheif_DIR=#{libheif_cmake}",
           "-Dpkgcfg_lib_JXL_jxl=#{formula_opt_lib("jpeg-xl")}/libjxl.so",
           "-Dpkgcfg_lib_JXL_THREADS_jxl_threads=#{formula_opt_lib("jpeg-xl")}/libjxl_threads.so",
           "-Dlunasvg_DIR=#{formula_opt_prefix("lunasvg")}/lib/cmake/lunasvg",
           "-Dminizip-ng_DIR=#{formula_opt_prefix("minizip-ng")}/lib/cmake/minizip-ng",
           "-Dplutovg_DIR=#{formula_opt_prefix("plutovg")}/lib/cmake/plutovg",
           "-DOpenEXR_DIR=#{formula_opt_prefix("openexr")}/lib/cmake/OpenEXR",
           "-DImath_DIR=#{formula_opt_prefix("imath")}/lib/cmake/Imath",
           "-Dlibdeflate_DIR=#{formula_opt_prefix("libdeflate")}/lib/cmake/libdeflate",
           "-Dopenjph_DIR=#{formula_opt_prefix("openjph")}/lib/cmake/openjph",
           "-Dtinyxml2_DIR=#{formula_opt_prefix("tinyxml2")}/lib/cmake/tinyxml2",
           "-DWebP_DIR=#{formula_opt_prefix("webp")}/share/WebP/cmake",
           "-Dzstd_DIR=#{formula_opt_prefix("zstd")}/lib/cmake/zstd",
           "-Dlibjpeg-turbo_DIR=#{formula_opt_prefix("jpeg-turbo")}/lib/cmake/libjpeg-turbo",
           "-DGIF_INCLUDE_DIR=#{formula_opt_prefix("giflib")}/include",
           "-DGIF_LIBRARY=#{formula_opt_prefix("giflib")}/lib/libgif.so",
           "-DTIFF_INCLUDE_DIR=#{formula_opt_prefix("libtiff")}/include",
           "-DTIFF_LIBRARY=#{formula_opt_prefix("libtiff")}/lib/libtiff.so",
           "-DCMAKE_PREFIX_PATH=#{cmake_prefix_path}",
           "-DZLIB_ROOT=#{zlib_ng}",
           "-DZLIB_INCLUDE_DIR=#{zlib_ng}/include",
           "-DZLIB_LIBRARY=#{zlib_ng}/lib/libz.so",
           "-DPNG_PNG_INCLUDE_DIR=#{formula_opt_prefix("libpng")}/include",
           "-DPNG_LIBRARY=#{formula_opt_prefix("libpng")}/lib/libpng.so",
           "-DCMAKE_CXX_FLAGS=-march=armv8-a+crc -I#{buildpath}/jthread/source",
           "-DCMAKE_EXE_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DCMAKE_SHARED_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DSNOW_SHOT_ENABLE_STRICT_COMPILE=OFF",
           "-DSNOW_APPS_BUILD_SNOW_SHOT=ON",
           "-DSNOW_APPS_BUILD_SNOW_SHOT_MINI=OFF",
           "-DSNOW_APPS_BUILD_IMAGE_VIEWER=OFF",
           "-DSNOW_APPS_BUILD_TESTS=OFF",
           "-DSNOW_APPS_BUILD_BENCHMARKS=OFF",
           "-DSNOW_APPS_BUILD_DRAW_ENGINE_DEMO=OFF",
           "-DSNOW_APPS_ENABLE_RELEASE_OPTIMIZATION=OFF",
           "-DSNOW_SHOT_BUILD_TESTS=OFF",
           "-DSNOW_SHOT_ENABLE_MCP=OFF",
           "-DSNOW_SHOT_QT_STATIC=OFF",
           "-DSNOW_SHOT_OCR_ASSET_MANIFEST=#{buildpath}/snow_shot/packaging/snow-shot-ocr-asset-manifest-arm64.json",
           "-DSNOW_APPS_API_BASE_URL=https://snowshot.top",
           "-DSNOW_APPS_FREE_TRANSLATION_API_BASE_URL=https://index-translate.bilibili.com/v1",
           *std_cmake_args
    system "cmake", "--build", "build", "--target", "snow_shot",
           "snow_ocr_inprocess_build", "--parallel"

    # The remainder packages the exact Qt and non-platform ELF closure into
    # the HAP. It runs only in the private Qt/CLT CI image, never on a device.
    package_hap(qt, clt, ohos_sdk, qt_tls)
    unsigned_hap = "hap-proj/entry/build/default/outputs/default/entry-default-unsigned.hap"
    libexec.install unsigned_hap => "snow-shot-unsigned.hap"
    (libexec/"snow-shot-install").write (res/"snow-shot-install.sh").read
    chmod 0555, libexec/"snow-shot-install"
    (bin/"snow-shot-app").write_env_script libexec/"snow-shot-install",
      SNOW_SHOT_HAP: libexec/"snow-shot-unsigned.hap",
      SNOW_SHOT_HDC: formula_opt_prefix("ohos-sdk-toolchains")/"hdc"
    bin.install_symlink "snow-shot-app" => "snow-shot"
  end

  def build_qt_tls(qt_sdk, native_sdk)
    source = buildpath/"qtbase-source"
    mkdir_p source
    resource("qtbase").stage do
      root = Pathname.new(".")
      unless (root/"src/corelib").directory?
        entries = Dir.children(".").map { |entry| Pathname.new(entry) }
        root = entries.find { |entry| (entry/"src/corelib").directory? }
      end
      odie "could not find the qtbase source root" unless root
      cp_r root.children, source
    end
    node_addon_api = buildpath/"qt-node-modules/node-addon-api"
    mkdir_p node_addon_api
    resource("node-addon-api").stage do
      root = Pathname.new(".")
      unless (root/"napi.h").file?
        entries = Dir.children(".").map { |entry| Pathname.new(entry) }
        root = entries.find { |entry| (entry/"napi.h").file? }
      end
      odie "could not find the node-addon-api headers" unless root
      cp_r root.children, node_addon_api
    end
    sdk_root = buildpath/"qt-ohos-sdk-root"
    mkdir_p sdk_root
    ln_sf native_sdk/"native", sdk_root/"native"
    openssl = formula_opt_prefix("openssl@4")
    build_dir = buildpath/"qtbase-build"
    mkdir_p build_dir
    configure = source/"configure"
    cd build_dir do
      # Keep Homebrew's build flags and search paths from leaking into the
      # SDK-only Qt build.
      with_env(CFLAGS: "", CXXFLAGS: "", CPPFLAGS: "", LDFLAGS: "",
               CMAKE_PREFIX_PATH: nil, PKG_CONFIG_PATH: nil,
               OHOS_SDK_ROOT: sdk_root.to_s, OHOS_ARCH: "arm64-v8a",
               QT_HOST_PATH: qt_sdk.to_s) do
        system configure,
               "-release", "-shared", "-openssl-runtime", "-platform", "ohos-clang",
               "-qt-host-path", qt_sdk.to_s,
               "-prefix", (build_dir/"qt-install").to_s,
               "-extprefix", (build_dir/"qt-install").to_s,
               "-nomake", "examples", "-nomake", "tests",
               "-no-gui", "-no-widgets", "-no-dbus",
               "--",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DOPENSSL_ROOT_DIR=#{openssl}",
               "-DOPENSSL_INCLUDE_DIR=#{openssl}/include",
               "-DNODE_ADDON_API_ROOT=#{node_addon_api.parent}",
               "-DNodeAddonApi_INCLUDE_DIR=#{node_addon_api}",
               "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
        system "ninja", "-j#{ENV.make_jobs}", "Core", "Network", "QTlsBackendOpenSSLPlugin"
      end
    end
    library = build_dir/"lib/libQt6Network.so"
    plugin = build_dir/"plugins/tls/libqopensslbackend.so"
    odie "the QtNetwork rebuild did not produce libQt6Network.so" unless library.file?
    odie "the QtNetwork rebuild did not produce the OpenSSL TLS plugin" unless plugin.file?
    payload = buildpath/"qt-tls-payload"
    mkdir_p payload
    cp library, payload/"libQt6Network.so"
    cp plugin, payload/"libqopensslbackend.so"
    rm_r source
    rm_r build_dir
    rm_r node_addon_api.parent
    rm_r sdk_root
    [payload/"libQt6Network.so", payload/"libqopensslbackend.so"]
  end

  def package_qt_tls(qt_tls, stage, command_line_tools, native_sdk)
    library, plugin = qt_tls
    patchelf = formula_opt_prefix("patchelf")/"bin/patchelf"
    network = buildpath/"libQt6Network.so.6"
    cp library, network
    system patchelf, "--set-soname", "libQt6Network.so.6",
           "--replace-needed", "libQt6Core.so", "libQt6Core.so.6",
           "--replace-needed", "libz.so", "libz.so.1",
           "--force-rpath", "--set-rpath", "$ORIGIN", network
    tls_plugin = buildpath/"libqopensslbackend.so"
    cp plugin, tls_plugin
    system patchelf, "--replace-needed", "libQt6Network.so", "libQt6Network.so.6",
           "--replace-needed", "libQt6Core.so", "libQt6Core.so.6",
           "--force-rpath", "--set-rpath", "$ORIGIN:$ORIGIN/..", tls_plugin
    sign_tool = command_line_tools/"sdk/default/openharmony/toolchains/lib/binary-sign-tool"
    odie "binary-sign-tool is missing from the Qt/CLT CI image" unless sign_tool.executable?
    # The OHOS compiler already writes a .codesign section; it makes
    # binary-sign-tool reject the file, so drop it before signing.
    objcopy = native_sdk/"native/llvm/bin/llvm-objcopy"
    odie "llvm-objcopy is missing from the OHOS SDK" unless objcopy.executable?
    [network, tls_plugin].each do |binary|
      system objcopy, "--remove-section=.codesign", binary
      signed = Pathname("#{binary}.signed")
      system sign_tool, "sign", "-selfSign", "1", "-inFile", binary, "-outFile", signed
      mv signed, binary
      chmod 0755, binary
    end
    libs = stage/"entry/libs/arm64-v8a"
    cp network, libs/"libQt6Network.so.6"
    mkdir_p libs/"tls"
    cp tls_plugin, libs/"tls/libqopensslbackend.so"
  end

  def package_hap(qt_sdk, command_line_tools, native_sdk, qt_tls)
    sdk_overlay = buildpath/"hap-sdk/default/openharmony"
    mkdir_p sdk_overlay
    (command_line_tools/"sdk/default").children.each do |entry|
      next if entry.basename.to_s == "openharmony"

      ln_s entry, sdk_overlay.parent/entry.basename
    end
    (command_line_tools/"sdk/default/openharmony").children.each do |component|
      if component.basename.to_s != "native"
        ln_s component, sdk_overlay/component.basename
        next
      end
      native_overlay = sdk_overlay/"native"
      mkdir_p native_overlay/"llvm"
      component.children.each do |entry|
        next if entry.basename.to_s == "llvm"

        ln_s entry, native_overlay/entry.basename
      end
      (component/"llvm").children.each do |entry|
        next if entry.basename.to_s == "bin"

        ln_s entry, native_overlay/"llvm"/entry.basename
      end
      ln_s native_sdk/"native/llvm/bin", native_overlay/"llvm/bin"
    end
    ENV["DEVECO_SDK_HOME"] = (buildpath/"hap-sdk").to_s
    ENV["HOS_SDK_HOME"] = (buildpath/"hap-sdk").to_s
    res = Pathname(__FILE__).parent.parent.parent/"Resources/snow-shot-app"
    stage = buildpath/"hap-proj"
    app_lib = buildpath/"build/snow_shot/libsnow_shot.so"
    runtime_lib_dirs = [app_lib.dirname.to_s] + recursive_dependencies.filter_map do |dependency|
      library_directory = dependency.to_formula.opt_lib
      library_directory.to_s if library_directory.directory?
    end.uniq
    (buildpath/"hd.json").write <<~JSON
      {
        "application-binary": "#{app_lib}",
        "harmonyos-package-source-directory": "#{qt_sdk}/src/harmonyos/templates",
        "harmonyos-app-name": "snow-shot",
        "harmonyos-app-bundle-name": "com.social4hyq.snowshot",
        "ndk-root": "#{native_sdk}/native",
        "qtLibsDirectory": "#{qt_sdk}/lib",
        "qtPluginsDirectory": "#{qt_sdk}/plugins",
        "qtLibExecsDirectory": "#{qt_sdk}/libexec",
        "qtHostDirectory": "#{qt_sdk}",
        "extra-libs-dirs": #{JSON.generate(runtime_lib_dirs)}
      }
    JSON
    # Let harmonydeployqt write to the build log directly. Redirecting it to a
    # file and reading that file back on failure hid the real error: the
    # redirect target was never created, so the failure path raised ENOENT.
    # Formula#system returns nil on success and raises BuildError on failure,
    # so do not test its return value.
    system qt_sdk/"bin/harmonydeployqt", "--input", buildpath/"hd.json",
           "--output", stage, "--no-build", "--verbose"

    system "python3", res/"support/scripts/stage-ohos-app-icon-assets.py",
           "--template", res/"ohos-template", "--stage", stage
    system "python3", res/"support/scripts/stage-ohos-app-label-assets.py",
           "--template", res/"ohos-template", "--stage", stage
    cp res/"ohos-template/entry/src/main/ets/qability/QAbility.ets",
       stage/"entry/src/main/ets/qability/QAbility.ets"
    # The Qt HAP template has no statusBarView extension, and the Qt OHOS tray
    # plugin registers its icon through @kit.StatusBarExtensionKit, which needs
    # one. Ship a minimal extension plus the page the quick panel loads, and
    # declare both in the generated project.
    mkdir_p stage/"entry/src/main/ets/statusbar"
    %w[StatusBarAbility.ets StatusBarPage.ets].each do |name|
      cp res/"ohos-template/entry/src/main/ets/statusbar"/name,
         stage/"entry/src/main/ets/statusbar"/name
    end
    inreplace stage/"entry/src/main/resources/base/profile/main_pages.json",
              "    \"pages/UiExtensionNativeNode\"\n",
              "    \"pages/UiExtensionNativeNode\",\n    \"statusbar/StatusBarPage\"\n"
    # Anchor on the prefix only: harmonydeployqt may already have filled the
    # %%INSERT_PERMISSIONS%% placeholder by the time this runs.
    extension_declaration = [
      "    \"extensionAbilities\": [",
      "      {",
      "        \"name\": \"StatusBarExtensionAbility\",",
      "        \"srcEntry\": \"./ets/statusbar/StatusBarAbility.ets\",",
      "        \"type\": \"statusBarView\",",
      "        \"exported\": false",
      "      }",
      "    ],",
      "    \"requestPermissions\": [",
    ].join("\n")
    inreplace stage/"entry/src/main/module.json5",
              "    \"requestPermissions\": [", extension_declaration
    mkdir_p stage/"entry/src/main/cpp/types/libsnow_shot"
    cp res/"ohos-template/entry/src/main/cpp/types/libsnow_shot/index.d.ts",
       stage/"entry/src/main/cpp/types/libsnow_shot/index.d.ts"

    libs = stage/"entry/libs/arm64-v8a"
    cp buildpath/"build/snow_shot/libsnow_shot_image_codec_backend.so", libs
    cp formula_opt_prefix("zlib-ng-compat")/"lib/libz.so.1", libs/"libz.so.1"
    cp buildpath/"build/cargo/aarch64-unknown-linux-ohos/release/libsnow_ocr_inprocess.so", libs
    package_qt_tls(qt_tls, stage, command_line_tools, native_sdk)
    ocr_output = stage/"entry/src/main/resources/rawfile/ocr"
    system "python3", res/"support/scripts/stage-ohos-ocr-assets.py",
           "--source-manifest", buildpath/"snow_shot/packaging/snow-shot-ocr-asset-manifest-arm64.json",
           "--runtime", libs/"libsnow_ocr_inprocess.so",
           "--model-root", buildpath/"ocr-models",
           "--output-root", ocr_output
    qr_output = stage/"entry/src/main/resources/rawfile/qrcode"
    mkdir_p qr_output
    %w[detect.prototxt detect.caffemodel sr.prototxt sr.caffemodel].each do |name|
      cp buildpath/"artifacts/qr-models-wechat"/name, qr_output/name
    end

    # The generated Qt template includes demo-only dependencies and a dead NAPI
    # sample build; remove them so the shipped HAP contains only QAbility + Qt.
    inreplace stage/"build-profile.json5", '"signingConfig": "default",', ""
    cd stage do
      inreplace "oh-package.json5", /"devDependencies": \{[^}]*\},?/, ""
      inreplace "entry/build-profile.json5", /^  "buildOption": \{.*?^  \},\n/m, ""
      system "node", (command_line_tools/"hvigor/bin/hvigorw.js").to_s, "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end
    hap = stage/"entry/build/default/outputs/default/entry-default-unsigned.hap"
    system "python3", (res/"support/scripts/finalize-ohos-ocr-manifest.py").to_s, hap.to_s
    system "python3", (res/"support/scripts/add-ohos-module-permissions.py").to_s, hap.to_s
    sdk_lib_dir = native_sdk/"native/sysroot/usr/lib/aarch64-linux-ohos"
    clt_lib_dir = command_line_tools/"sdk/default/openharmony/native/sysroot/usr/lib/aarch64-linux-ohos"
    system "python3", res/"support/scripts/test-snow-shot-hap-runtime-closure.py",
           hap, "--readelf", native_sdk/"native/llvm/bin/llvm-readelf",
           "--system-lib-dir", sdk_lib_dir, "--system-lib-dir", clt_lib_dir
  end

  def caveats
    <<~EOS
      The HAP is unsigned in the bottle. Connect and unlock the device, then run
      `snow-shot-app install`: app-installer handles Huawei Developer login, local
      debug profile generation, signing, installation, and launch.
    EOS
  end

  test do
    hap = libexec/"snow-shot-unsigned.hap"
    assert_path_exists hap
    assert_predicate bin/"snow-shot", :symlink?
    assert_match "Usage: snow-shot-app <command>", shell_output("#{bin}/snow-shot --help")
    assert_match "Usage: snow-shot-app <command>", shell_output("#{bin}/snow-shot-app --help")
    assert_match "Usage: snow-shot-app <command>", shell_output(bin/"snow-shot-app")
    assert_match "unknown command: bogus", shell_output("#{bin}/snow-shot-app bogus 2>&1", 2)
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    installer_args = testpath/"hap-installer-args"
    (fake_bin/"hap-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
    SH
    chmod 0755, fake_bin/"hap-installer"
    (fake_bin/"hdc").write "#!/bin/sh\necho 127.0.0.1:1\n"
    chmod 0755, fake_bin/"hdc"
    with_env(PATH: "#{fake_bin}:#{ENV["PATH"]}", SNOW_SHOT_HDC: (fake_bin/"hdc").to_s) do
      shell_output(bin/"snow-shot-app")
      refute_path_exists installer_args
      shell_output("#{bin}/snow-shot-app install --no-start")
    end
    args = installer_args.read.lines(chomp: true)
    assert_equal ["--hap", hap.to_s], args.first(2)
    assert_equal %w[--bundle-id com.social4hyq.snowshot --app-name SnowShot --module entry
                    --ability QAbility --no-start], args.drop(2)
    listing = shell_output("unzip -l #{hap}")
    %w[
      libsnow_shot.so libqohos.so libQt6Widgets.so.6
      rawfile/ocr/asset-manifest.json
      rawfile/qrcode/detect.prototxt rawfile/qrcode/detect.caffemodel
      rawfile/qrcode/sr.prototxt rawfile/qrcode/sr.caffemodel
    ].each do |name|
      assert_match name, listing
    end
    refute_match "libs/arm64-v8a/libsnow_ocr_process.so", listing
    assert_match "libs/arm64-v8a/tls/libqopensslbackend.so", listing
    assert_match "libs/arm64-v8a/libQt6Network.so.6", listing
    network = Utils.safe_popen_read("unzip", "-p", hap,
                                   "libs/arm64-v8a/libQt6Network.so.6").b
    assert_includes network, "QSslSocket".b
    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.snowshot", manifest.dig("app", "bundleName")
    assert_equal "QAbility", manifest.dig("module", "abilities", 0, "name")
    permissions = manifest.dig("module", "requestPermissions").map { |item| item["name"] }
    assert_includes permissions, "ohos.permission.CUSTOM_SCREEN_CAPTURE"
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_includes permissions, "ohos.permission.GET_NETWORK_INFO"
    assert_equal "$media:app_icon", manifest.dig("module", "abilities", 0, "icon")
    system "unzip", "-q", hap, "resources/rawfile/ocr/asset-manifest.json",
           "libs/arm64-v8a/libsnow_ocr_inprocess.so", "-d", testpath/"ocr-check"
    ocr_manifest = JSON.parse((testpath/"ocr-check/resources/rawfile/ocr/asset-manifest.json").read)
    runtime = testpath/"ocr-check/libs/arm64-v8a/libsnow_ocr_inprocess.so"
    descriptor = ocr_manifest.fetch("runtime").fetch("files").fetch(0)
    assert_equal descriptor.fetch("size"), runtime.size
    assert_equal descriptor.fetch("sha256"), Digest::SHA256.file(runtime).hexdigest
    system "unzip", "-tq", hap
  end
end
