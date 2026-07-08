class Bun < Formula
  desc "— JavaScript runtime for HarmonyOS aarch64 (stable)"
  homepage "https://github.com/oven-sh/bun"
  # This formula is fully rewritten from upstream because Bun on HarmonyOS requires
  # 50+ OHOS-specific patches, L4 self-bootstrap via bun-bootstrap, a
  # pre-populated WebKit cache, and a Rust nightly toolchain with -Zbuild-std.
  # All patches are pre-applied on the openharmony branch of social4hyq/ohos-bun.
  # Upstream formula cannot accommodate these build requirements.
  url "https://gh-proxy.com/https://github.com/social4hyq/ohos-bun.git", revision: "28603b97c40560e5bca7a51a27e91e17efb52e70", branch: "openharmony"
  version "1.4.0"
  license "MIT"
  revision 23
  head "https://github.com/oven-sh/bun.git", branch: "main"

  livecheck do
    url :stable
    regex(/^bun-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-v1.4.0-r23"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adc0f5aacb0e6f7ab03248cda54a81a35d7363aac3639e78884b4d109a366020"
  end

  # ── Dependencies (all bare names, zero changes when graduating to harmonybrew/core) ──
  depends_on "bun-bootstrap" => :build # Bootstrap: `bun bd` itself is a bun script
  depends_on "bun-webkit" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "node"
  depends_on "openssl@3" => :build # only build-time rust-nightly cargo links libssl/libcrypto
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "social4hyq/core/icu4c@78" => :build # qualified: icu4c@78 exists in both taps
  # ohos-sdk is build-time only: used to sign rust-nightly binaries, the
  # clang-sign wrapper, and the final bun binary. Runtime signing (PackageInstaller
  # .node/.so, dlopen, bun build --compile) is now handled in-process by ohos_sign.
  depends_on "ohos-sdk" => :build

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

  # ── OHOS patches are pre-applied on the openharmony branch of social4hyq/ohos-bun ──
  # See commits pr3-vendor / pr4-build-target / pr5-ohos-runtime / pr6-rust-compat /
  # pr7-shared-cfg-gate / pr8-upstream-sync / pr9-ohos-fixes on that branch.
  # Vendor patch files (patches/lolhtml/crate-type.patch, patches/zstd/ohos-qsort-r.patch)
  # are committed directly in the source tree; ninja applies them during the build.

  def install
    # buildpath = bun source root (patches already auto-applied by Homebrew).
    # Build logic is fully inlined (mirroring git.rb in harmonybrew core — no external scripts).
    # All dependencies are declared via depends_on: llvm@21 (signing clang/lld), icu4c@78,
    # bun-webkit (JSC static libs), bun-bootstrap (L3 driver, bootstrap).

    # ── Fix host platform detection in config.ts: on OHOS process.platform returns "openharmony" ──
    inreplace buildpath/"scripts/build/config.ts",
              "plat === \"linux\"",
              "plat === \"linux\" || plat === \"openharmony\""

    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    # ── Pre-populate WebKit cache (bun bd's fetch checks .identity to skip download) ──
    # webkit.ts.patch performs the same operation inside the source function, but the
    # ninja fetch step may run before the source function takes effect — belt and suspenders.
    webkit_ver = "c9ad5813fd23bd8b98b0738abc3d037ec716aa92"
    brew_home = Pathname.new(Dir.home)
    wc = brew_home/".bun/build-cache/webkit-#{webkit_ver[0...16]}-ohos-arm64"
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
      ln_sf Formula["social4hyq/core/icu4c@78"].opt_lib/a, wc/"lib"/a
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

    # ── bun install (bun.lock committed on openharmony branch matches package.json) ──
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
    rust_ver = resource("rust-nightly").version.to_s  # e.g. "nightly-2026-05-06"
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
      sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
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
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["libxml2"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["zlib"].opt_lib.to_s
    # rust-nightly cargo NEEDS libssl.so/libcrypto.so (brew openssl@3);
    # without injecting, musl startup hits "Error relocating ... symbol not found" → exit 127.
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["openssl@3"].opt_lib.to_s
    # llvm@21 only ships llvm-strip; the bun build script needs strip.
    # cc/c++ must sign link artifacts: the OHOS kernel refuses to exec unsigned ELF, and cargo's
    # build-script-build binary runs natively → "Permission denied (os error 13)". clang-sign runs
    # binary-sign-tool automatically after linking; it only signs link output and skips -c/-E/-S/-M/-MM
    # (an .o with a .codesign section makes the final binary report
    # ".codesign section already exists", which binary-sign-tool refuses to sign).
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    clang_sign = buildpath/".bin/clang-sign"
    clang_sign.write <<~SHELL
      #!/bin/sh
      set -e
      "#{llvm.opt_bin}/clang" "$@"
      rc=$?
      [ $rc -ne 0 ] && exit $rc
      out=""; prev=""
      for arg in "$@"; do
        [ "$prev" = "-o" ] && out="$arg"
        prev="$arg"
      done
      has_link=1
      for a in "$@"; do
        case "$a" in -c|-E|-S|-M|-MM) has_link=0 ;; esac
      done
      [ "$has_link" = "1" ] || exit 0
      [ -z "$out" ] && [ -f a.out ] && out=a.out
      [ -n "$out" ] && [ -f "$out" ] || exit 0
      magic=$(od -An -N4 -tx1 "$out" 2>/dev/null | tr -d ' \\n')
      [ "$magic" = "7f454c46" ] || exit 0
      readelf -S "$out" 2>/dev/null | grep -q '\\.codesign' && exit 0
      tmp="${out}.unsigned.$$"
      signed="${out}.signed.$$"
      mv -f "$out" "$tmp"
      if "#{Formula["ohos-sdk"].opt_bin}/binary-sign-tool" sign -selfSign 1 -inFile "$tmp" -outFile "$signed" >/dev/null 2>&1 && [ -f "$signed" ]; then
        chmod +x "$signed"
        # OHOS/tmpfs ETXTBSY fix: write signed output to staging path, then rename
        # atomically to final path.  binary-sign-tool wrote and closed $signed; after
        # mv the final inode has no in-flight write FDs, so cargo can exec immediately.
        sync
        mv -f "$signed" "$out"
        rm -f "$tmp"
      else
        rm -f "$signed" 2>/dev/null
        mv -f "$tmp" "$out"
      fi
      exit 0
    SHELL
    chmod 0755, clang_sign
    clang_sign_pp = buildpath/".bin/clang++-sign"
    clang_sign_pp.write clang_sign.read.gsub("/clang\"", "/clang++\"")
    chmod 0755, clang_sign_pp
    ln_sf clang_sign,    buildpath/".bin/cc"
    ln_sf clang_sign_pp, buildpath/".bin/c++"
    # bun flags.ts expects ohosCrossLibs to contain libcxx/include/v1/ and libcxxabi/include/.
    # The corresponding headers in llvm@21 live at include/aarch64-linux-ohos/c++/v1/.
    # Create the matching layout under buildpath so build.ts finds it via OHOS_LLVM_PREFIX.
    # The bun build system in OHOS mode uses -nostdinc++ and looks under build/ohos-cross-libs/.
    # Pre-create that dir and symlink it to llvm@21's headers and libs to satisfy flags.ts include/link paths.
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
    ENV.prepend_path "PATH", buildpath/".bin"
    # Put bootstrap bun in PATH: `bun bd` is itself a bun script, so a working bun must exist first.
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    # The rustc_wrapper shim injected by superenv is #!/bin/bash; OHOS has no /bin/bash → exec ENOENT.
    ENV.delete("RUSTC_WRAPPER")
    # cargo needs a CA bundle when pulling from crates.io (OHOS musl has no system CA store).
    ca_bundle = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV["SSL_CERT_FILE"]  = ca_bundle.to_s
    ENV["CURL_CA_BUNDLE"] = ca_bundle.to_s
    # Channel pinned by rust-toolchain.toml; OHOS target goes through -Zbuild-std (pr4 patch)
    ENV["RUSTUP_TOOLCHAIN"] = "nightly-2026-05-06"
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s
    # bun rust.ts:647/source.ts:1411 uses this env to swap in the linker for the OHOS target link.
    ENV["OHOS_BUN_SIGNING_LINKER"] = clang_sign_pp.to_s
    # The cargo host build-script links via CC (cc-rs crate); if unsigned, build-script-build
    # hits EACCES on exec. CC goes through clang-sign so link artifacts are signed automatically.
    ENV["CC"]  = clang_sign.to_s
    ENV["CXX"] = clang_sign_pp.to_s
    # bun's tmpdir() reads TMPDIR first; superenv may reset it to ~/.tmp/ which is noexec
    # on OHOS — cargo build-script-build hits ETXTBSY. Force EL2 tmp (executable, user-owned).
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"

    # ── Build: bun scripts/build.ts (equivalent to invoking `bun bd`) ──
    # --os=ohos --arch=aarch64 triggers the OHOS compile path in the bun source (pr4+pr5 patch).
    sysroot = Formula["ohos-sdk"].opt_prefix/"native/sysroot"
    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=off",
           "--ohos-sdk-root=#{Formula["ohos-sdk"].opt_prefix}",
           "--ohos-sysroot=#{sysroot}"

    # The release profile produces `bun-profile` (unstripped, ~455MB) + `bun`
    # (stripped, ~105MB). Prefer the stripped version — smaller and ready-to-run.
    out = buildpath/"build/release/bun"
    odie "bun binary missing after build: #{out}" unless out.exist?
    # The OHOS kernel refuses to exec unsigned ELF. The bun build system does not sign itself
    # (the signing tool is OHOS-specific), so sign explicitly after install.
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    unsigned = "#{out}.unsigned"
    mv out, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", out
    chmod 0755, out
    rm unsigned
    bin.install out => "bun"
  end

  def post_install
    # Pre-cache node-gyp@11 in bunx cache so napi tests don't timeout
    # on first download when running in parallel.
    # Brew sandbox may set a TMPDIR with mismatched ownership; use the
    # standard EL2 tmp which the current user owns.
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"
    ENV.prepend_path "PATH", Formula["node"].opt_bin
    system bin/"bun", "--bun", "x", "node-gyp@11", "--version"
  end

  def caveats
    <<~EOS
      Bun (stable, #{version}) for HarmonyOS aarch64.
      Built via L4 self-bootstrap (bun-bootstrap → bun bd).
    EOS
  end

  test do
    assert_match "4294967296", shell_output("#{bin}/bun -e 'console.log(2**32)'")
    assert_match version.to_s, shell_output("#{bin}/bun --version")
  end
end
