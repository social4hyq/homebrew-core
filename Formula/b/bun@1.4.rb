class BunAT14 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  # Need git checkout to build. Alternatively could set GIT_SHA if we extract the commit.
  url "https://github.com/oven-sh/bun.git",
      tag:      "bun-v1.4.2",
      revision: "744846f844374847c902b5e7fd59b4342a51ef99"
  license all_of: [
    "MIT",
    "LGPL-2.0-or-later", # JavaScriptCore

    # Other libraries, https://github.com/oven-sh/bun/blob/main/LICENSE.md#linked-libraries
    # Unlike upstream, OHOS statically links ICU (see BUN_OHOS_ICU_ROOT
    # below), so its license is included rather than ignored.
    "Apache-2.0",        # boringssl, simdutf, uSockets, highway, uWebsockets, Tigerbeetle
    "BSD-2-Clause",      # libarchive, libbase64, libspng
    "BSD-3-Clause",      # lol-html, libwebp, zstd
    "IJG",               # libjpeg-turbo
    "LGPL-2.1-or-later", # tinycc
    "Unicode-3.0",       # ICU (statically linked on OHOS)
    "Zlib",              # zlib-ng
    "Apache-2.0" => { with: "LLVM-exception" }, # __cxa_thread_atexit
  ]
  # gitcode PR #21183 review round: dep/license/patch-naming cleanup requires
  # rebuilding the same upstream version.
  revision 13
  livecheck do
    url :stable
    regex(/^bun[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun@1.4-v1.4.2-r22"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a5741e8542afd6ee1b02c5bc6f13c5346952b7c05de9150c9c6c5de843e470e"
  end

  depends_on "cmake" => :build
  # Provides libstdc++ for the WebKit/JSC C++ toolchain (see LD_LIBRARY_PATH
  # in install below).
  depends_on "gcc" => :build
  # Required by the WebKit build (HTML/CSS name-table codegen); not
  # preinstalled on the OHOS build image the way it is on other CI runners.
  depends_on "gperf" => :build
  depends_on "llvm@21" => :build # LLVM 22 PR: https://github.com/oven-sh/bun/pull/34299
  depends_on "ninja" => :build
  # Empirically required: without node on PATH the build's first ninja batch
  # dies with exit 127 (command not found) right after the WebKit configure;
  # the bootstrap bun covers the codegen jsRuntime, so some WebKit-phase
  # tooling execs node directly. Do not drop this dep without a full CI run.
  depends_on "node" => :build
  # libssl.so for rustup/cargo's TLS crate downloads (see LD_LIBRARY_PATH in
  # install below).
  depends_on "openssl@3" => :build
  depends_on "rustup" => :build # needs nightly as uses `-Z` flags and unstable `#![feature(...)]`
  # libz.so for build-time tools that dynamically link it (see
  # LD_LIBRARY_PATH in install below).
  depends_on "zlib-ng-compat" => :build

  uses_from_macos "perl" => :build # for webkit
  uses_from_macos "python" => :build # for webkit
  uses_from_macos "ruby" => :build # for webkit
  uses_from_macos "unzip" => :build

  on_linux do
    # Upstream depends on icu4c@78 at runtime (dynamic link). OHOS statically
    # links it instead (see BUN_OHOS_ICU_ROOT below), so it is :build-only.
    depends_on "icu4c@78" => :build
    depends_on "lld@21" => :build
  end

  on_intel do
    depends_on "nasm" => :build
  end

  fails_with :gcc do
    cause "uses clang-specific flags"
  end

  # Bootstrap with the same Bun version as upstream CI,
  # https://github.com/oven-sh/bun/blob/bun-v#{version}/.buildkite/Dockerfile
  # musl (not upstream's glibc build): OHOS userspace is musl-compatible, and
  # this only runs codegen/build scripts — nothing from it ships in the bottle.
  resource "bootstrap" do
    url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-aarch64-musl.zip"
    sha256 "5385e978107ce4934298d8d6afe9bfbb898683f6cc23e6753a0da60bc60c5b81"
  end

  # Apply all exported OHOS patches. Filenames are the patched file's repo
  # path with "/" -> "_" (dots from the file's own extension are kept as
  # dots), e.g. src/bun_core/Global.rs -> src_bun_core_Global.rs.patch. Three
  # of these create a *new* file whose own path happens to end in .patch
  # (patches/tinycc/tccgen.c.patch, patches/webkit/suspend-resume.patch,
  # patches/zstd/ohos-qsort-r.patch) — those are vendored-dep patches
  # consumed later by tinycc.ts/zstd.ts's own `patches:` array and by
  # fetch_webkit below, not by this loop.
  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/bun@1.4/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # Performing a manual shallow git clone since a full clone of WebKit repo is ~18GB in size
  # and brew's unpack strategy will duplicate a resource requiring over 36GB of disk space.
  # This exceeds limit of GitHub-hosted runners. A shallow git clone is instead ~7GB.
  def fetch_webkit
    webkit_version = File.read("scripts/build/deps/webkit.ts")[/WEBKIT_VERSION = "(\h+)"/i, 1]
    odie "Unable to find WebKit version!" if webkit_version.blank?

    clone_args = %W[
      --branch=autobuild-#{webkit_version}
      --config=advice.detachedHead=false
      --config=core.fsmonitor=false
      --depth=1
    ]
    system "git", "clone", *clone_args, "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"

    # Homebrew's swiftc shim causes misconfiguration as Apple expects a valid installation
    on_linux do
      inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
                "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""
    end

    cd "vendor/WebKit" do
      # patches/webkit/suspend-resume.patch was materialized into buildpath
      # by the DSL patch loop above; apply it to the freshly cloned WebKit
      # checkout here, since vendor/WebKit only exists after the clone.
      suspend_patch = buildpath/"patches/webkit/suspend-resume.patch"
      odie "WebKit suspend patch missing: #{suspend_patch}" unless suspend_patch.file?
      system "git", "apply", "--check", suspend_patch
      system "git", "apply", suspend_patch
      odie "WebKit suspend fix missing" unless File.read("Source/WTF/wtf/Threading.h").include?("m_suspendRequested")
    end
  end

  # Based on https://github.com/oven-sh/bun/blob/main/CONTRIBUTING.md#building-webkit-locally--debug-mode-of-jsc
  def install
    bootstrap_version = File.read(".buildkite/Dockerfile")[/OLD_BUN_VERSION="v?(\d+(?:\.\d+)+)"/i, 1]
    odie "Update bootstrap to #{bootstrap_version}" if resource("bootstrap").version != bootstrap_version

    llvm = Formula["llvm@21"]
    channel = File.read("rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    rust_toolchain = "#{channel}-aarch64-unknown-linux-ohos"
    # Keep rustup's own state inside buildpath rather than $HOME (sandboxed build).
    rustup_home = buildpath/"rustup"
    ENV["RUSTUP_HOME"] = rustup_home
    ENV["CARGO_HOME"] = buildpath/"cargo"
    system "rustup", "toolchain", "install", rust_toolchain, "--profile", "minimal", "--component", "rust-src"
    rust_home = rustup_home/"toolchains"/rust_toolchain
    # Tells the rustup proxy binaries (cargo/rustc on PATH below) which
    # toolchain to use, since we never run `rustup default`.
    ENV["RUSTUP_TOOLCHAIN"] = rust_toolchain
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("gcc")/"gcc/current"
    # rustup/cargo fetch crates over TLS; OHOS has no default system CA
    # bundle path, so point both at Homebrew's own ca-certificates.
    ENV["SSL_CERT_FILE"] = ENV["CURL_CA_BUNDLE"] = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", formula_opt_bin("lld@21")

    # Nested dep builds run `cmake --build` without `--parallel`, four at a time
    # (the `dep` ninja pool), so each one spawns its own core-count worth of
    # compilers on top of the outer build and Homebrew's job limit is ignored.
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
    # Bootstrap bun (see the resource block above): build-time only, it
    # runs the build scripts.
    resource("bootstrap").stage("bootstrap")
    ENV.prepend_path "PATH", buildpath/"bootstrap"

    system "bun", "scripts/build.ts", "--profile=release-local", "--build-dir=build/release-local",
           "--canary=off", "--abi=ohos"

    bin.install "build/release-local/bun"
    bin.install_symlink bin/"bun" => "bunx"

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
