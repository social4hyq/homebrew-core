class BunAT14 < Formula
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
    "Zlib",              # zlib-ng
    "Apache-2.0" => { with: "LLVM-exception" }, # __cxa_thread_atexit
  ]
  # Upstream PR review fixes (signing split, flat patch series) require
  # rebuilding the same upstream version.
  revision 12
  livecheck do
    url :stable
    regex(/^bun[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun@1.4-v1.4.2-r20"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c39a2591aae344b5e77737bfbf6a91fd7f0d0e4da1aa2cd49121a3aefbd400fb"
  end

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "lld@21" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  # Empirically required: without node on PATH the build's first ninja batch
  # dies with exit 127 (command not found) right after the WebKit configure;
  # the bootstrap bun covers the codegen jsRuntime, so some WebKit-phase
  # tooling execs node directly. Do not drop this dep without a full CI run.
  depends_on "node" => :build
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "rustup" => :build
  depends_on "zlib-ng-compat" => :build

  fails_with :gcc do
    cause "uses clang-specific flags"
  end

  # Bootstrap Bun: the upstream Linux/musl official binary, used only to
  # run the codegen/build scripts during the build. Nothing from it ships
  # in the bottle. The OHOS userspace provides musl-compatible libc; the
  # GNU C++ runtime is supplied by the gcc dependency below.
  resource "bootstrap" do
    url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-aarch64-musl.zip"
    sha256 "b98e0ad3625c5c00d1d5b5ff55605c7adddbfae151861e68ade57b2d3b8703bb"
  end

  # Apply all exported OHOS patches (flat, pkgsrc-style names). The three
  # entries in `inner` carry a vendored-dep patch as payload: applying the
  # outer patch materializes the inner file at its source-tree path.
  patch_root = Pathname(__dir__).parent.parent
  inner = %w[
    patch-patches_tinycc_tccgen_c_patch
    patch-patches_webkit_suspend-resume_patch
    patch-patches_zstd_ohos-qsort-r_patch
  ]
  Dir[(patch_root/"Patches/bun@1.4/*.patch").to_s].each do |path|
    next if inner.include?(Pathname(path).basename(".patch").to_s)

    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end
  inner.each do |stem|
    patch do
      file "Patches/bun@1.4/#{stem}.patch"
    end
  end

  def fetch_webkit
    webkit_version = File.read("scripts/build/deps/webkit.ts")[/WEBKIT_VERSION = "(\h+)"/i, 1]
    odie "Unable to find WebKit version!" if webkit_version.blank?

    system "git", "clone", "--branch=autobuild-#{webkit_version}",
           "--config=advice.detachedHead=false", "--config=core.fsmonitor=false",
           "--depth=1", "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"

    cd "vendor/WebKit" do
      # The suspend patch lives in this formula's patch directory
      # (Patches/bun@1.4/); applied here rather than via a DSL patch because
      # vendor/WebKit only exists after the clone above. Applying the
      # outer patch above wrote the inner patch file into the buildpath,
      # so it can be applied to the clone directly.
      suspend_patch = buildpath/"patches/webkit/suspend-resume.patch"
      odie "WebKit suspend patch missing: #{suspend_patch}" unless suspend_patch.file?
      system "git", "apply", "--check", suspend_patch
      system "git", "apply", suspend_patch
      odie "WebKit suspend fix missing" unless File.read("Source/WTF/wtf/Threading.h").include?("m_suspendRequested")
    end
    inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
              "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""
  end

  def install
    llvm = Formula["llvm@21"]
    channel = File.read("rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    rust_toolchain = "#{channel}-aarch64-unknown-linux-ohos"
    # rustup installs the aarch64-unknown-linux-ohos toolchain that
    # compiles bun itself (the rustc/cargo seed for this build); it is
    # used at build time only and never enters the bottle.
    rustup_home = buildpath/"rustup"
    ENV["RUSTUP_HOME"] = rustup_home
    ENV["CARGO_HOME"] = buildpath/"cargo"
    system "rustup", "toolchain", "install", rust_toolchain, "--profile", "minimal", "--component", "rust-src"
    rust_home = rustup_home/"toolchains"/rust_toolchain
    ENV["BUN_TOOLCHAIN_RUST"] = rust_home
    ENV["RUSTUP_TOOLCHAIN"] = rust_toolchain
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("gcc")/"gcc/current"
    ENV["SSL_CERT_FILE"] = ENV["CURL_CA_BUNDLE"] = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", formula_opt_bin("lld@21")
    # Bootstrap bun (see the resource block above): build-time only, it
    # runs the build scripts.
    (buildpath/"bootstrap").mkpath
    resource("bootstrap").stage do
      (buildpath/"bootstrap").install "bun"
    end
    ENV.prepend_path "PATH", buildpath/"bootstrap"
    ENV["CMAKE_BUILD_PARALLEL_LEVEL"] = ENV.make_jobs.to_s

    # The build resolves ICU via BUN_OHOS_ICU_ROOT. The staging dir carries
    # the keg's headers plus ONLY the static archives, so the link is
    # self-contained: the deployed binary must not depend on the keg's
    # shared libs at runtime.
    icu = formula_opt_prefix("icu4c@78")
    icu_stage = buildpath/"build/ohos-icu-static"
    icu_stage.mkpath
    (icu_stage/"include").make_symlink icu/"include"
    (icu_stage/"lib").mkpath
    Dir.glob("#{icu}/lib/*.a").each { |a| (icu_stage/"lib"/File.basename(a)).make_symlink a }
    ENV["BUN_OHOS_ICU_ROOT"] = icu_stage

    fetch_webkit
    ENV["BUN_BUILD_ABI"] = "ohos"
    system "bun", "scripts/build.ts", "--profile=release-local", "--build-dir=build/release-local",
           "--canary=off", "--abi=ohos"

    bin.install "build/release-local/bun"
    bin.install_symlink "bun" => "bunx"
    bash_completion.install "completions/bun.bash" => "bun"
    fish_completion.install "completions/bun.fish"
    zsh_completion.install "completions/bun.zsh" => "_bun"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bun --version")
    refute_match "canary", shell_output("#{bin}/bun --revision")

    system bin/"bun", "init", "--yes"
    assert_equal "Hello via Bun!", shell_output("#{bin}/bun run index.ts").chomp

    # bun self-signs the executables it produces, so ./test running below
    # also proves the self-signing path works.
    system bin/"bun", "build", "--compile", "--outfile=test", "index.ts"
    assert_equal "Hello via Bun!", shell_output("./test").chomp

    assert_match "< hello bun >", shell_output("#{bin}/bunx cowsay hello bun")

    # Test SQLite API which loads system library on macOS
    (testpath/"db.ts").write <<~TYPESCRIPT
      import { Database } from "bun:sqlite";
      const db = new Database(":memory:");
      db.run("create table students (name text, age integer)");
      db.run("insert into students (name, age) values ('Bob', 14)");
      db.run("insert into students (name, age) values ('Sue', 12)");
      db.run("insert into students (name, age) values ('Tim', 13)");
      const query = db.query("select name from students order by age asc");
      console.log(query.values().flat());
    TYPESCRIPT
    assert_equal '[ "Sue", "Tim", "Bob" ]', shell_output("#{bin}/bun run db.ts").chomp
  end
end
