class Bun < Formula
  desc "— JavaScript runtime for HarmonyOS aarch64 (stable)"
  homepage "https://github.com/oven-sh/bun"
  # This formula is fully rewritten from upstream because Bun on HarmonyOS requires
  # 50+ OHOS-specific patches, L4 self-bootstrap via bun-bootstrap, a
  # pre-populated WebKit cache, and a Rust nightly toolchain with -Zbuild-std.
  # All patches are pre-applied on the ohos-aarch64 branch of social4hyq/ohos-bun.
  # Upstream formula cannot accommodate these build requirements.
  url "https://github.com/social4hyq/ohos-bun.git", revision: "d5927317525ce4a1eb73a418acf567ca260cab7a", branch: "ohos-aarch64"
  version "1.4.0"
  license "MIT"
  revision 31
  head "https://github.com/oven-sh/bun.git", branch: "main"

  livecheck do
    url :stable
    regex(/^bun-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-v1.4.0-r31"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "16742500ad227373bbad3b1a384640e1faeeba2b35bcf8aed3686d753f449a94"
  end

  # ── Dependencies (all bare names, zero changes when graduating to harmonybrew/core) ──
  depends_on "bun-bootstrap" => :build # Bootstrap: `bun bd` itself is a bun script
  depends_on "bun-webkit" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "social4hyq/core/icu4c@78" => :build
  # only build-time rust-nightly cargo links libssl/libcrypto
  depends_on "node"
  # No runtime ohos-compat-shim dependency since r31: a vendored copy of the
  # shim is statically linked into the executable (emitShims in the source
  # tree, workarounds.ts "ohos-compat-shim-embed"), covering bun AND every
  # `bun build --compile` output without LD_PRELOAD.
  # ohos-sdk is build-time only: used to sign rust-nightly binaries, the
  # clang-sign wrapper, and the final bun binary. Runtime signing (PackageInstaller
  # .node/.so, dlopen, bun build --compile) is now handled in-process by ohos_sign.

  # Rust nightly (native OHOS host toolchain, needed by bun's libbun_rust.a).
  # OHOS is a Tier 3 target with no prebuilt rust-std, so bun uses -Zbuild-std
  # to build std from source, hence the rust-src component is required
  # (included in the full nightly host tarball).
  # Version aligned with the channel in bun-src/rust-toolchain.toml.
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    version "nightly-2026-05-06"
    sha256 "7e93009ca8eb40fa039ba7fce6d8d6e95646b6459a7582e4ea46308c7db00eb8"
  end

  # rust-src is distributed separately from the host tarball; required by bun
  # -Zbuild-std (otherwise cargo reports
  # "library/Cargo.lock does not exist, unable to build with the standard library").
  resource "rust-src" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-src-nightly.tar.gz"
    version "nightly-2026-05-06"
    sha256 "2bfd8eed73318df568cc5831083b11de986af6da5c66f140b73cf4ae365ceca3"
  end

  # ── OHOS patches are pre-applied on the ohos-aarch64 branch of social4hyq/ohos-bun ──
  # The branch is a linear series of feat/fix(ohos) commits kept in sync with
  # upstream oven-sh/bun main via merge (last: 87e50375f, upstream 6618e7f7e).
  # Vendor patch files (patches/zstd/ohos-qsort-r.patch) are committed directly
  # in the source tree; ninja applies them during the build.

  def install
    # buildpath = bun source root (patches already auto-applied by Homebrew).
    # Build logic is fully inlined (mirroring git.rb in harmonybrew core — no external scripts).
    # All dependencies are declared via depends_on: llvm@21 (signing clang/lld), icu4c@78,
    # bun-webkit (JSC static libs), bun-bootstrap (L3 driver, bootstrap).

    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    # ── Persistent build cache (vendor tarballs + webkit) ──
    # Default cacheDir is $HOME/.bun/build-cache, but brew's HOME is the
    # per-build .brew_home — the cache would be wiped every run and every
    # vendor tarball re-downloaded (GitHub is unreliable/blocked on OHOS).
    # Pin it to a stable EL2 path (same convention as rust_home below) and
    # pass --cache-dir so fetch-cli/webkit both hit it; pre-seed
    # <cache_dir>/tarballs to build fully offline.
    cache_dir = Pathname.new("/data/storage/el2/base/tmp/bun-build-cache")

    # ── Pre-populate WebKit cache (bun bd's fetch checks .identity to skip download) ──
    webkit_ver = "4895f45dfbd0d1226c4d41799887bc0ecb9f341b"
    wc = cache_dir/"webkit-#{webkit_ver[0...16]}-ohos-arm64"
    wc.mkpath
    File.write(wc/".identity", webkit_ver)
    (wc/"lib").mkpath
    %w[libJavaScriptCore.a libWTF.a libbmalloc.a].each do |a|
      ln_sf webkit.lib/a, wc/"lib"/a
    end
    (wc/"include").mkpath
    cd wc/"include" do
      ln_sf webkit.include/"webkit/JavaScriptCore", "JavaScriptCore"
      ln_sf webkit.include/"webkit/wtf", "wtf"
      ln_sf webkit.include/"webkit/bmalloc", "bmalloc"
      cp webkit.include/"webkit/cmakeconfig.h", "cmakeconfig.h"
    end
    %w[libicudata.a libicui18n.a libicuuc.a].each do |a|
      ln_sf formula_opt_lib("social4hyq/core/icu4c@78")/a, wc/"lib"/a
    end

    # ── Scaffold build/ohos-icu/{target,host} layout for bun's config.ts ──
    # bun config.ts:1013 defaults ohosIcuDir = <cwd>/build/ohos-icu/target,
    # which is the wrapper's build-icu.sh output path. Brew install never runs
    # build-icu.sh, so point this layout at icu4c@78 formula instead.
    # webkit.ts:472 also resolves hostBin = <ohosIcuDir>/../host/bin for ICU
    # data tools (genrb/genccode/gencmn/pkgdata) — symlink those too.
    icu = Formula["social4hyq/core/icu4c@78"]
    (buildpath/"build/ohos-icu/target/include").mkpath
    ln_sf icu.opt_include/"unicode", buildpath/"build/ohos-icu/target/include/unicode"
    (buildpath/"build/ohos-icu/target/lib").mkpath
    %w[libicudata.a libicui18n.a libicuuc.a].each do |a|
      ln_sf icu.opt_lib/a, buildpath/"build/ohos-icu/target/lib"/a
    end
    (buildpath/"build/ohos-icu/host/bin").mkpath
    %w[genrb genccode gencmn pkgdata].each do |t|
      ln_sf icu.opt_bin/t, buildpath/"build/ohos-icu/host/bin"/t if (icu.opt_bin/t).exist?
    end

    # ── bun install (bun.lock committed on ohos-aarch64 branch matches package.json) ──
    # bun.lock was updated to remove ohos-signpost (replaced by in-process ohos_sign crate).
    # bun install resolves all packages from ~/.bun/install/cache without network access.
    # (bun-tracestrings: github-hosted dep; GitHub is blocked on OHOS but the package is pre-cached
    # at @GH@oven-sh-bun.report-912ca63@@@1 so no download is attempted.)
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    system "bun", "install"
    # node-fallbacks has its own bun.lock; pre-populate cache so ninja's
    # subsequent `bun install --frozen-lockfile` can verify without network.
    system "bun", "install", "--cwd", "src/node-fallbacks"

    # ── Regenerate native binlink test packages with openharmony in os[] ──
    # Upstream test packages (test-native-binlink-*-target) list os:["darwin","linux","win32"].
    # ── Rust nightly (persistent cache keyed by toolchain date; skips reinstall+signing if already done) ──
    # OHOS is a Tier 3 target: bun uses -Zbuild-std to build std, which requires rust-src (in full tarball).
    rust_ver = resource("rust-nightly").version.to_s # e.g. "nightly-2026-05-06"
    rust_home = Pathname.new("/data/storage/el2/base/tmp/rust-#{rust_ver}")
    rust_ready = rust_home/"BREW_SIGNED_OK"

    unless rust_ready.exist?
      rust_home.mkpath
      resource("rust-nightly").stage do
        # The host tarball contains rustc/cargo/rust-std; install via install.sh.
        # Use sh explicitly: OHOS superenv PATH has no bash for the shebang.
        system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
      end
      resource("rust-src").stage do
        system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
      end

      # ── Sign the rust binaries (OHOS kernel refuses to exec unsigned ELF → cargo exits 127) ──
      sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
      Dir.glob(rust_home/"**/*").each do |f|
        next unless File.file?(f)
        next if File.symlink?(f)
        next if File.read(f, 4, mode: "rb") != "\x7fELF"

        tmp = "#{f}.unsigned"
        mv f, tmp
        system sign_tool, "sign", "-selfSign", "1", "-inFile", tmp, "-outFile", f
        chmod 0755, f
        rm tmp
      end

      rust_ready.write("signed #{Time.now}\n")
    end

    # ── Build environment (PATH + env) ──
    # lld from llvm@21 has runtime deps on libxml2/zlib; brew superenv strips system lib paths,
    # so inject them explicitly so ld.lld can find them (consistent with bun-webkit).
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("libxml2").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib").to_s
    # rust-nightly cargo NEEDS libssl.so/libcrypto.so (brew openssl@3);
    # without injecting, musl startup hits "Error relocating ... symbol not found" → exit 127.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3").to_s
    # llvm@21 only ships llvm-strip; the bun build script needs strip.
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    # bun flags.ts expects ohosCrossLibs to contain libcxx/include/v1/ and libcxxabi/include/.
    ohos_cross = buildpath/"build/ohos-cross-libs"
    (ohos_cross/"libcxx/include").mkpath
    (ohos_cross/"libcxxabi").mkpath
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxx/include/v1"
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxxabi/include"
    %w[libcxx libcxxabi libunwind].each do |d|
      (ohos_cross/d/"lib").mkpath
      Dir[llvm.opt_lib/"aarch64-linux-ohos/*.a"].each do |a|
        ln_sf a, ohos_cross/d/"lib"/File.basename(a)
      end
    end
    # Use llvm@21's cc/c++ shims (HOMEBREW_PREFIX/bin/cc, c++) — they wrap clang 21
    # with LLD --code-sign. This replaces the legacy clang-sign wrapper that ran
    # binary-sign-tool after linking.
    # Put bootstrap bun in PATH: `bun bd` is itself a bun script, so a working bun must exist first.
    ENV.prepend_path "PATH", buildpath/".bin"
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    ENV.delete("RUSTC_WRAPPER")
    ca_bundle = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV["SSL_CERT_FILE"]  = ca_bundle.to_s
    ENV["CURL_CA_BUNDLE"] = ca_bundle.to_s
    ENV["RUSTUP_TOOLCHAIN"] = "nightly-2026-05-06"
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s
    # LLD --code-sign injects .codesign at link time (llvm@21 CodeSign patch).
    # cc/c++ are llvm@21 shims that already pass -Wl,--code-sign; set them as
    # CC/CXX so cargo build-script artifacts are signed on exec.
    ENV["OHOS_BUN_SIGNING_LINKER"] = (HOMEBREW_PREFIX/"bin/c++").to_s
    ENV["CC"]  = (HOMEBREW_PREFIX/"bin/cc").to_s
    ENV["CXX"] = (HOMEBREW_PREFIX/"bin/c++").to_s
    # No CARGO_BUILD_JOBS cap: the historical ETXTBSY came from the llvm@21
    # cc/c++ shims re-signing outputs in-place with no sync barrier; the shim
    # now signs at link time only (LLD --code-sign). Verified zero ETXTBSY at
    # full parallelism in CI (ohos-build.yml).
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"

    # ── Build: bun scripts/build.ts (equivalent to invoking `bun bd`) ──
    # --os=ohos --arch=aarch64 triggers the OHOS compile path in the bun source.
    sysroot = formula_opt_prefix("ohos-sdk")/"native/sysroot"
    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=off",
           "--cache-dir=#{cache_dir}",
           "--ohos-sdk-root=#{formula_opt_prefix("ohos-sdk")}",
           "--ohos-sysroot=#{sysroot}"

    # The release profile produces `bun-profile` (unstripped, ~455MB) + `bun`
    # (stripped, ~105MB). Prefer the stripped version — smaller and ready-to-run.
    out = buildpath/"build/release/bun"
    odie "bun binary missing after build: #{out}" unless out.exist?
    # The OHOS kernel refuses to exec unsigned ELF. The bun build system does not sign itself
    # (the signing tool is OHOS-specific), so sign explicitly after install.
    sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
    unsigned = "#{out}.unsigned"
    mv out, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", out
    chmod 0755, out
    rm unsigned
    # The compat shim is statically linked into the binary since r31 (source
    # tree emitShims + workarounds.ts "ohos-compat-shim-embed"), so no
    # LD_PRELOAD or OHOS_COMPAT_SHIM_ENABLE wrapper is needed — linkat and
    # symlinkat are default-on in the shim since 0.2.0. The real ELF stays
    # at libexec/bin/bun, symlinked from bin/bun; opt_libexec is
    # HOMEBREW_PREFIX-relative so the bottle stays relocatable across the
    # HOMEBREW_CELLAR flip.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/bun"
    chmod 0755, libexec/"bin/bun"
    bin.install_symlink opt_libexec/"bin/bun" => "bun"
  end

  def post_install
    # Pre-cache node-gyp@11 in bunx cache so napi tests don't timeout
    # on first download when running in parallel.
    # Brew sandbox may set a TMPDIR with mismatched ownership; use the
    # standard EL2 tmp which the current user owns.
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"
    ENV.prepend_path "PATH", formula_opt_bin("node")
    system bin/"bun", "--bun", "x", "node-gyp@11", "--version"
  end

  def caveats
    <<~EOS
      Bun (stable, #{version}) for HarmonyOS aarch64.
      Built via L4 self-bootstrap (bun-bootstrap → bun bd).

      Native addon support (node-gyp / N-API): bun auto-configures CC=cc,
      CXX=c++, LDFLAGS=-Wl,--code-sign on OHOS. Install llvm@21 to provide
      the signed toolchain (cc/c++ → clang + LLD --code-sign):
        brew install llvm@21

      ohos-compat-shim is statically embedded in the binary (r31+): OHOS-blocked
      syscalls (close_range, fchmodat2, getcwd, ...) are covered without
      LD_PRELOAD, in bun and in `bun build --compile` outputs. linkat and
      symlinkat interposers are also default-on. Disable per-symbol via
      OHOS_COMPAT_SHIM_DISABLE.
    EOS
  end

  test do
    assert_match "4294967296", shell_output("#{bin}/bun -e 'console.log(2**32)'")
    assert_match version.to_s, shell_output("#{bin}/bun --version")
  end
end
