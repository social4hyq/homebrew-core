class SnowImageViewer < Formula
  desc "Color-managed image viewer from Snow Apps, unsigned HAP (sign at install)"
  homepage "https://github.com/mg-chao/snow-shot"
  url "https://github.com/mg-chao/snow-shot/archive/refs/tags/v1.6.5_snow-shot.tar.gz"
  sha256 "125059b53d029b9fba8307868595c2eed478b4bf129b88c22d4a4dbb0f30c0d6"
  license "GPL-3.0-or-later"
  revision 3

  livecheck do
    url "https://github.com/mg-chao/snow-shot.git"
    regex(/^v?(\d+(?:\.\d+)+)_snow-shot$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/snow-image-viewer-v1.6.5-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0b9c74e76807932398cf6f6b6aeae2e313967b8201345c4c9151dc0490e843cb"
  end

  # These libraries are copied into the HAP after their ELF dependency graph
  # is walked by harmonydeployqt; they are build-time-only tap dependencies.
  depends_on "bzip2" => :build
  depends_on "cmake" => :build
  depends_on "expat" => :build
  depends_on "fontconfig" => :build
  depends_on "freetype" => :build
  depends_on "gettext" => :build
  depends_on "libpng" => :build
  depends_on "muslext" => :build
  depends_on "ninja" => :build
  depends_on "node" => :build # Hvigor invokes npm, which finds Node through PATH.
  depends_on "ohos-hap-clt" => :build
  depends_on "ohos-sdk" => :build
  depends_on "openjdk" => :build
  depends_on "qt-ohos-sdk" => :build
  depends_on "zlib" => :build
  # Qt6Core links zstd (rcc compresses resources); the NDK sysroot has none.
  depends_on "zstd" => :build

  # C++20 <stop_token>/jthread polyfill: the OHOS NDK libc++ predates them.
  # Header-only reference implementation by the std::jthread proposal author.
  resource "jthread" do
    url "https://github.com/josuttis/jthread/archive/0fa8d394254886c555d6faccd0a3de819b7d47f8.tar.gz"
    sha256 "d3a20e0c1b2758c4545b0a97490afa2986e39c8b4387c3dba2007def742cbeb0"
  end

  resource "command-line-tools" do
    url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
    sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  end

  # Accept the 6.13.0 kit (upstream pins 6.12.0 EXACT for their audits).
  # OHOS NDK libc++ lacks C++20 <stop_token>/jthread: route the includes to the
  # vendored jthread polyfill (formula resource). The strict-warning set is
  # tuned for MSVC/Xcode clangs; do not fail the OHOS clang-15 build on warnings.
  # HarmonyOS hosts load Qt apps as a shared library via the qohos platform
  # plugin, not as a spawned executable.
  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/snow-image-viewer/*.patch").to_s].each do |path|
    patch :p1 do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  def install
    qt = formula_opt_prefix("qt-ohos-sdk")/"libexec/qt-6.13.0-dev"
    odie "Qt OHOS SDK missing" unless (qt/"lib/cmake/Qt6/Qt6Config.cmake").exist?
    clt = buildpath/"command-line-tools"
    hap_clt = formula_opt_bin("ohos-hap-clt")/"ohos-hap-clt"
    archive = resource("command-line-tools")
    archive.fetch
    system hap_clt.to_s, "stage", clt.to_s, archive.cached_download.to_s

    resource("jthread").stage do
      cp_r "source", buildpath/"jthread-source"
    end
    ohos_sdk = formula_opt_prefix("ohos-sdk")

    # The Qt host tools load Qt and zstd while running in the build container.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zstd")
    ENV.prepend_path "LD_LIBRARY_PATH", qt/"lib"
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it (only ever lowering).
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    system "cmake", "-B", "build", "-S", "snow_image_viewer", "-G", "Ninja",
           "-DCMAKE_TOOLCHAIN_FILE=#{qt}/lib/cmake/Qt6/qt.toolchain.cmake",
           "-DQT_CHAINLOAD_TOOLCHAIN_FILE=#{ohos_sdk}/native/build/cmake/ohos.toolchain.cmake",
           "-DOHOS_ARCH=arm64-v8a",
           "-DVulkanHeaders_DIR=#{qt}/share/vk-shim/lib/cmake/VulkanHeaders",
           "-DCMAKE_CXX_FLAGS=-I#{buildpath}/jthread-source -march=armv8-a+crc",
           "-DCMAKE_EXE_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DCMAKE_SHARED_LINKER_FLAGS=-L#{qt}/lib -lc++_shared",
           "-DCMAKE_PREFIX_PATH=#{qt}",
           *std_cmake_args
    system "cmake", "--build", "build", "--target", "snow_image_viewer"

    # The compiler's own codesign section lets executables run but the app
    # library is dlopen'd on device: re-sign with binary-sign-tool.
    app_lib = buildpath/"build/libsnow_image_viewer.so"
    sign_tool = ohos_sdk/"bin/binary-sign-tool"
    system sign_tool, "sign", "-selfSign", "1", "-inFile", app_lib,
           "-outFile", buildpath/"libsnow_image_viewer.signed"
    # NB: `install` here would recurse into Formula#install (arity 0).
    cp buildpath/"libsnow_image_viewer.signed", app_lib
    chmod "+x", app_lib

    # harmonydeployqt collects the Qt libraries/plugins and generates the
    # ArkUI shell project from the in-SDK template. Explicit installation
    # directories are required: without them the tool silently deploys only
    # the app library. extra-libs-dirs also lets its llvm-readobj walk include
    # the non-Qt runtime dependencies (fontconfig, freetype, zstd, ...).
    runtime_lib_dirs = %w[zstd muslext fontconfig freetype expat gettext libpng bzip2 zlib].map do |name|
      (formula_opt_prefix(name)/"lib").to_s
    end
    (buildpath/"hd.json").write <<~JSON
      {
        "application-binary": "#{app_lib}",
        "harmonyos-package-source-directory": "#{qt}/src/harmonyos/templates",
        "harmonyos-app-name": "snow-image-viewer",
        "harmonyos-app-bundle-name": "com.social4hyq.snowimageviewer",
        "ndk-root": "#{ohos_sdk}/native",
        "qtLibsDirectory": "#{qt}/lib",
        "qtPluginsDirectory": "#{qt}/plugins",
        "qtLibExecsDirectory": "#{qt}/libexec",
        "qtHostDirectory": "#{qt}",
        "extra-libs-dirs": #{JSON.generate(runtime_lib_dirs)}
      }
    JSON
    system qt/"bin/harmonydeployqt", "--input", "hd.json",
           "--output", "hap-proj", "--no-build", "--verbose"

    # harmonydeployqt assumes libz is a system library and skips it, but the
    # HarmonyOS PC application namespace has no libz.so.1. freetype needs it.
    cp "#{formula_opt_prefix("zlib")}/lib/libz.so.1", "hap-proj/entry/libs/arm64-v8a/"

    # No signingConfig: hvigor produces the unsigned artifact only.
    inreplace "hap-proj/build-profile.json5", '"signingConfig": "default",', ""
    cd "hap-proj" do
      # Template devDeps (@ohos/hypium/hamock) are test-only frameworks the
      # build does not need; fetching them from the ohpm registry is flaky
      # from CI runners, so drop them. The remaining entry deps are file:-
      # local typing stubs, and ohpm itself pings the registry even with no
      # dependencies — so skip the install entirely and let hvigor work from
      # the checked-in sources.
      inreplace "oh-package.json5", /"devDependencies": \{[^}]*\},?/, ""
      # The template's demo napi cpp (hello.cpp) is dead weight for the Qt
      # shell, and its bisheng cmake toolchain file was stripped from the
      # slim CLT; drop the native build option together with its buildOption
      # wrapper (the closing brace belongs to that wrapper).
      inreplace "entry/build-profile.json5", /^  "buildOption": \{.*?^  \},\n/m, ""
      ENV["JAVA_HOME"] = formula_opt_prefix("openjdk").to_s
      ENV.prepend_path "PATH", formula_opt_bin("openjdk")
      ENV.prepend_path "PATH", formula_opt_bin("node")
      system hap_clt.to_s, "hvigor", clt.to_s, "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
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
    %w[
      libsnow_image_viewer.so
      libqohos.so
      libmuslext.so.1
      libQt6Core.so.6
      libQt6Gui.so.6
      libQt6Widgets.so.6
      libQt6Svg.so
      libfontconfig.so.1
      libfreetype.so.6
      libintl.so.8
      libz.so.1
      libzstd.so.1
    ].each { |name| assert_match name, listing }
    system "unzip", "-tq", hap
  end
end
