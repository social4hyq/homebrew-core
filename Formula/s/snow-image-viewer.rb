class SnowImageViewer < Formula
  desc "Color-managed image viewer from Snow Apps, unsigned HAP (sign at install)"
  homepage "https://github.com/mg-chao/snow-apps"
  url "https://github.com/mg-chao/snow-apps/archive/refs/tags/v1.5.2_snow-shot.tar.gz"
  sha256 "e2f3ebd5f19f25e7132255aa96fb1660d1009e98bf4e37c8e78bfaa1da78c39f"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  # Qt6Core links zstd (rcc compresses resources); the NDK sysroot has none.
  depends_on "zstd" => :build

  # C++20 <stop_token>/jthread polyfill: the OHOS NDK libc++ predates them.
  # Header-only reference implementation by the std::jthread proposal author.
  resource "jthread" do
    url "https://github.com/josuttis/jthread/archive/0fa8d394254886c555d6faccd0a3de819b7d47f8.tar.gz"
    sha256 "d3a20e0c1b2758c4545b0a97490afa2986e39c8b4387c3dba2007def742cbeb0"
  end

  # 0001: accept the 6.13.0 kit (upstream pins 6.12.0 EXACT for their audits).
  # 0002: OHOS NDK libc++ lacks C++20 <stop_token>/jthread: route the includes
  #      to the vendored jthread polyfill (formula resource).
  # 0003: the strict-warning set is tuned for MSVC/Xcode clangs; do not fail
  #      the OHOS clang-15 build on warnings.
  # 0004: HarmonyOS hosts load Qt apps as a shared library via the qohos
  #      platform plugin, not as a spawned executable.
  patch :p1 do
    file "Patches/snow-image-viewer/0001-qt-toolchain-6.13.0.patch"
  end
  patch :p1 do
    file "Patches/snow-image-viewer/0002-ohos-libcxx-polyfill.patch"
  end
  patch :p1 do
    file "Patches/snow-image-viewer/0003-port-warnings.patch"
  end
  patch :p1 do
    file "Patches/snow-image-viewer/0004-ohos-app-library.patch"
  end

  def install
    # CI runs in the private qt-ohos-ci image (selected via
    # OHOS_CI_IMAGE_OVERRIDES): the HAP toolchain from electron-ohos-ci plus
    # the augmented Qt 6.13 OHOS SDK at /opt/qt-ohos (qtbase + qtsvg +
    # linguist tools + Vulkan shim; recipe in the ohos-snow project).
    qt = Pathname.new("/opt/qt-ohos/qt-6.13.0-dev")
    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "snow-image-viewer builds only in the qt-ohos-ci CI image" unless (qt/"lib/cmake/Qt6/Qt6Config.cmake").exist?

    resource("jthread").stage do
      cp_r "source", buildpath/"jthread-source"
    end
    ohos_sdk = formula_opt_prefix("ohos-sdk")

    # Build-time Qt tools (moc/rcc/lrelease) are OHOS ELFs running natively
    # in the aarch64 container; hvigor additionally needs the CLT clang
    # runtimes and the libhilog stderr adapter.
    ld_path = "#{qt}/lib:#{clt}/lib:" \
              "#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos:" \
              "#{formula_opt_prefix("zstd")}/lib"
    ENV["LD_LIBRARY_PATH"] = ld_path
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it (only ever lowering).
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    system "cmake", "-B", "build", "-S", "snow_image_viewer", "-G", "Ninja",
           "-DCMAKE_TOOLCHAIN_FILE=#{qt}/lib/cmake/Qt6/qt.toolchain.cmake",
           "-DQT_CHAINLOAD_TOOLCHAIN_FILE=#{ohos_sdk}/native/build/cmake/ohos.toolchain.cmake",
           "-DOHOS_ARCH=arm64-v8a",
           "-DVulkanHeaders_DIR=/opt/qt-ohos/vk-shim/lib/cmake/VulkanHeaders",
           "-DCMAKE_CXX_FLAGS=-I#{buildpath}/jthread-source -march=armv8-a+crc",
           "-DCMAKE_EXE_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DCMAKE_SHARED_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DCMAKE_PREFIX_PATH=#{qt}",
           *std_cmake_args
    system "cmake", "--build", "build", "--target", "snow_image_viewer"

    # The compiler's own codesign section lets executables run but the app
    # library is dlopen'd on device: re-sign with binary-sign-tool.
    app_lib = buildpath/"build/libsnow_image_viewer.so"
    sign_tool = clt/"sdk/default/openharmony/toolchains/lib/binary-sign-tool"
    system sign_tool, "sign", "-selfSign", "1", "-inFile", app_lib,
           "-outFile", buildpath/"libsnow_image_viewer.signed"
    install buildpath/"libsnow_image_viewer.signed", app_lib
    chmod "+x", app_lib

    # harmonydeployqt collects the Qt libraries/plugins and generates the
    # ArkUI shell project from the in-SDK template.
    (buildpath/"hd.json").write <<~JSON
      {
        "application-binary": "#{app_lib}",
        "harmonyos-package-source-directory": "#{qt}/src/harmonyos/templates",
        "harmonyos-app-name": "snow-image-viewer",
        "harmonyos-app-bundle-name": "com.social4hyq.snowimageviewer"
      }
    JSON
    system qt/"bin/harmonydeployqt", "--input", "hd.json",
           "--output", "hap-proj", "--no-build"

    # Qt6Core's zstd is not a Qt library, so harmonydeployqt does not collect
    # it; the app library needs it at runtime on device.
    (buildpath/"hap-proj/entry/libs/arm64-v8a").mkpath
    cp "#{formula_opt_prefix("zstd")}/lib/libzstd.so.1", "hap-proj/entry/libs/arm64-v8a/"

    # No signingConfig: hvigor produces the unsigned artifact only.
    inreplace "hap-proj/build-profile.json5", '"signingConfig": "default",', ""
    cd "hap-proj" do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      cd "entry" do
        system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
               "--mode", "module", "-p", "product=default", "--no-daemon"
      end
    end

    libexec.install "hap-proj/entry/build/default/outputs/default/entry-default-unsigned.hap" =>
                    "snow-image-viewer-unsigned.hap"
  end

  def caveats
    <<~EOS
      The HAP is UNSIGNED: developer certificates bind to a device UDID, so
      signing happens on your machine, not at bottling time.

      Sign and install with your own DevEco auto-sign materials (one-time
      setup with DevEco Studio or deveco-cli), then install:
        bm install -p <signed>.hap
    EOS
  end

  test do
    hap = libexec/"snow-image-viewer-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "module.json", listing
    assert_match "libsnow_image_viewer.so", listing
  end
end
