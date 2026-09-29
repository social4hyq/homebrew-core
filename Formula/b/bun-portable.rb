class BunPortable < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  url "https://github.com/oven-sh/bun.git",
      tag:      "bun-v1.4.2",
      revision: "744846f844374847c902b5e7fd59b4342a51ef99"
  license all_of: [
    "MIT",
    "LGPL-2.0-or-later", # JavaScriptCore
    "Apache-2.0",        # boringssl, simdutf, uSockets, highway, uWebsockets, Tigerbeetle
    "BSD-2-Clause",      # libarchive, libbase64, libspng
    "BSD-3-Clause",      # lol-html, libwebp, zstd
    "IJG",               # libjpeg-turbo
    "LGPL-2.1-or-later", # tinycc
    "Unicode-3.0",       # ICU
    "Zlib",              # zlib-ng
    "Apache-2.0" => { with: "LLVM-exception" }, # __cxa_thread_atexit
  ]

  livecheck do
    url :stable
    regex(/^bun[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  keg_only "it is an alternative build of the bun formula with ICU linked statically"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "lld@21" => :build
  depends_on "llvm@21" => [:build, :test]
  depends_on "ninja" => :build
  depends_on "openssl@3" => :build
  depends_on "rustup" => :build
  depends_on "zlib-ng-compat" => :build

  uses_from_macos "perl" => :build
  uses_from_macos "python" => :build
  uses_from_macos "ruby" => :build
  uses_from_macos "unzip" => :build

  resource "bootstrap" do
    url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-aarch64-musl.zip"
    sha256 "5385e978107ce4934298d8d6afe9bfbb898683f6cc23e6753a0da60bc60c5b81"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/bun/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  def install
    bootstrap_version = File.read(".buildkite/Dockerfile")[/OLD_BUN_VERSION="v?(\d+(?:\.\d+)+)"/i, 1]
    odie "Update bootstrap to #{bootstrap_version}" if resource("bootstrap").version != bootstrap_version

    inreplace "scripts/build/flags.ts", "-march=armv8-a+crc", ENV["HOMEBREW_OPTFLAGS"].to_s
    inreplace "scripts/build/bun.ts",
              '"-licudata", "-licui18n", "-licuuc"',
              '"-l:libicui18n.a", "-l:libicuuc.a", "-l:libicudata.a"'

    channel = File.read("rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    rust_toolchain = "#{channel}-aarch64-unknown-linux-ohos"
    system "rustup", "toolchain", "install", rust_toolchain, "--profile", "minimal", "--component", "rust-src"
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("gcc")/"gcc/current"
    ENV.prepend_path "PATH", Pathname(Dir.home)/".rustup/toolchains"/rust_toolchain/"bin"
    ENV["CMAKE_BUILD_PARALLEL_LEVEL"] = ENV.make_jobs.to_s

    webkit_version = File.read("scripts/build/deps/webkit.ts")[/WEBKIT_VERSION = "(\h+)"/i, 1]
    odie "Unable to find WebKit version!" if webkit_version.blank?
    system "git", "clone", "--branch=autobuild-#{webkit_version}", "--depth=1",
           "--config=advice.detachedHead=false", "--config=core.fsmonitor=false",
           "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"
    inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
              "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""
    system "git", "-C", "vendor/WebKit", "apply", buildpath/"patches/webkit/suspend-resume.patch"

    resource("bootstrap").stage("bootstrap")
    ENV.prepend_path "PATH", buildpath/"bootstrap"

    system "bun", "run", "build:release:local", "--canary=off", "--abi=ohos"
    bin.install "build/release-local/bun"
    bin.install_symlink bin/"bun" => "bunx"

    bash_completion.install "completions/bun.bash" => "bun"
    fish_completion.install "completions/bun.fish"
    zsh_completion.install "completions/bun.zsh" => "_bun"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bun --version")
    refute_match "libicu", shell_output("#{formula_opt_bin("llvm@21")}/llvm-readelf -d #{bin}/bun")

    system bin/"bun", "init", "--yes"
    assert_equal "Hello via Bun!", shell_output("#{bin}/bun run index.ts").chomp

    system bin/"bun", "build", "--compile", "--outfile=test", "index.ts"
    refute_match "libicu", shell_output("#{formula_opt_bin("llvm@21")}/llvm-readelf -d ./test")
    assert_equal "Hello via Bun!", shell_output("./test").chomp
  end
end
