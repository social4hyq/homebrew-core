class Bun < Formula
  desc "— JavaScript runtime for HarmonyOS aarch64 (stable)"
  homepage "https://github.com/oven-sh/bun"
  # This formula is fully rewritten from upstream because Bun on HarmonyOS requires
  # 50+ OHOS-specific patches (pr3-pr8), L4 self-bootstrap via bun-bootstrap, a
  # pre-populated WebKit cache, and a Rust nightly toolchain with -Zbuild-std.
  # Upstream formula cannot accommodate these build requirements.
  url "https://gh-proxy.com/https://github.com/oven-sh/bun.git", revision: "1498d7b77a5a6fd18075425aef4fc7b737ec8e08"
  version "1.4.0"
  license "MIT"
  revision 9
  head "https://github.com/oven-sh/bun.git", branch: "main"

  livecheck do
    url :stable
    regex(/^bun-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-v1.4.0-r7"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a26a56f05f326a9467585a77066bcf9168852e416f3f98cc3a3714e56b9d70af"
  end

  # ── Dependencies (all bare names, zero changes when graduating to harmonybrew/core) ──
  depends_on "bun-bootstrap" => :build # Bootstrap: `bun bd` itself is a bun script
  depends_on "bun-webkit" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "node" => :build
  depends_on "openssl@3" => :build # only build-time rust-nightly cargo links libssl/libcrypto
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "social4hyq/core/icu4c@78" => :build # qualified: icu4c@78 exists in both taps
  # ohos-sdk stays runtime: bun calls binary-sign-tool at runtime in three places
  # (PackageInstaller signs downloaded .node files; dlopen ensures .so is signed;
  # `bun build --compile` signs its output). OHOS refuses to exec unsigned ELF.
  depends_on "ohos-sdk"

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

  # ── OHOS patches (mirroring the patch do file pattern from git.rb) ──
  # Homebrew auto-applies these to buildpath (= bun source root) before def install.
  # Declared in PR order (pr3 → pr7, order-sensitive).
  # Each patch must have a comment explaining its purpose and upstream issue
  # (Homebrew audit requirement).
  # Note: vendor patches (crate-type/ohos-qsort-r) do not go through git apply;
  # instead the install step copies them into bun's patches/ directory and ninja
  # applies them as file dependencies during the build.
  patch :p1 do
    # pr3-vendor: OHOS adaptation for the zstd dep build script
    file "Patches/bun/pr3-vendor/zstd.ts.patch"
  end
  # pr4-build-target: OHOS cross-compilation target support (OS="ohos", triple, sysroot/SDK config)
  patch :p1 do
    # build.ts adds --ohos-sysroot / --ohos-sdk-root command-line options
    file "Patches/bun/pr4-build-target/build.ts.patch"
  end
  patch :p1 do
    # OHOS links libc/pthread/dl and local WebKit ICU; skip smoke test during cross-compilation
    file "Patches/bun/pr4-build-target/bun.ts.patch"
  end
  patch :p1 do
    # OHOS musl lacks GNU extensions (memmem/getservbyport_r); exclude them in c-ares config.h
    file "Patches/bun/pr4-build-target/cares.ts.patch"
  end
  patch :p1 do
    # Add OS="ohos", hostCc field and sysroot/SDK/cross-libs/ICU cross-compilation config
    file "Patches/bun/pr4-build-target/config.ts.patch"
  end
  patch :p1 do
    # OHOS compile/link flags: triple, sysroot, libc++, PIE, 8MB stack, no zstd debug,
    # + dynamic symbol list + version script (exposes napi_/node_api_ for .node dlopen)
    file "Patches/bun/pr4-build-target/flags.ts.patch"
  end
  patch :p1 do
    # OHOS also disables MI_NO_SET_VMA_NAME (VMA label debug sugar)
    file "Patches/bun/pr4-build-target/mimalloc.ts.patch"
  end
  patch :p1 do
    # Add aarch64-unknown-linux-ohos target; linker can go through the signing wrapper
    file "Patches/bun/pr4-build-target/rust.ts.patch"
  end
  patch :p1 do
    # dep_host_cc invokes binary-sign-tool for signing after linking; OHOS native cargo uses the signing linker
    file "Patches/bun/pr4-build-target/source.ts.patch"
  end
  patch :p1 do
    # Broaden LLVM version to 21–23; add OHOS LLVM22 search paths and install hints
    file "Patches/bun/pr4-build-target/tools.ts.patch"
  end
  patch :p1 do
    # Add OHOS prebuilt/ICU selection and cross-compilation CMake config (sysroot, libc++ headers, ICU tools)
    file "Patches/bun/pr4-build-target/webkit.ts.patch"
  end
  patch :p1 do
    # Add OHOS branch to bun scripts/utils.mjs tmpdir() (fallback to /data/local/tmp/$HOME/tmp)
    file "Patches/bun/pr4-build-target/utils.mjs.patch"
  end
  patch :p1 do
    # Add ohos-signpost dependency and postinstall probe hook (fills in detect-libc and other deps)
    file "Patches/bun/pr4-build-target/package.json.patch"
  end
  patch :p1 do
    # Add Libc::Ohos enum and triple parsing; platform string reports "ohos"; support file:// registration
    file "Patches/bun/pr4-build-target/compile_target.rs.patch"
  end
  patch :p1 do
    # bun upgrade download suffix for OHOS uses -ohos (a new branch alongside musl/android)
    file "Patches/bun/pr4-build-target/upgrade_command.rs.patch"
  end
  # pr8-upstream-sync: sync the lockfile that is out of sync with upstream package.json.
  # Not a standalone OHOS change — upstream package.json bumped esbuild 0.25→0.28,
  # but bun.lock still pins 0.25.12; sync here so bun install resolves consistently.
  patch :p1 do
    file "Patches/bun/pr8-upstream-sync/node-fallbacks-esbuild-lockfile.patch"
  end
  # pr5-ohos-runtime: OHOS-specific runtime substitutions
  # (syscall fallbacks, vfork→fork, signing, platform=openharmony)
  patch :p1 do
    # On OHOS process.platform returns "openharmony" (aligning with Node naming)
    file "Patches/bun/pr5-ohos-runtime/BunProcess.cpp.patch"
  end
  patch :p1 do
    # OHOS maps the external OS name to openharmony/OpenHarmony (so optional deps resolve correctly)
    file "Patches/bun/pr5-ohos-runtime/Global.rs.patch"
  end
  patch :p1 do
    # Add IS_OHOS / IS_GLIBC; IS_MUSL now includes ohos too
    file "Patches/bun/pr5-ohos-runtime/env.rs.patch"
  end
  patch :p1 do
    # OHOS skips fchmodat2, getcwd falls back to "/", and the signing tool is invoked before dlopen
    file "Patches/bun/pr5-ohos-runtime/lib.rs.patch"
  end
  patch :p1 do
    # OHOS build artifacts invoke binary-sign-tool for signing and chmod 755 (seccomp requirement)
    file "Patches/bun/pr5-ohos-runtime/build_command.rs.patch"
  end
  patch :p1 do
    # OHOS Bun.build({compile}) JS API mirrors the CLI compile sign hook
    file "Patches/bun/pr5-ohos-runtime/js_bundle_completion_task.rs.patch"
  end
  patch :p1 do
    # OHOS sets $PWD; pipes are marked socket+non-blocking to avoid blocking infinite loops
    file "Patches/bun/pr5-ohos-runtime/filter_run.rs.patch"
  end
  patch :p1 do
    # OHOS sets $PWD (bash uses stat instead of getcwd); CWD EPERM is silent and falls back to $HOME
    file "Patches/bun/pr5-ohos-runtime/run_command.rs.patch"
  end
  patch :p1 do
    # Add openharmony to the legal OS list for pm scan
    file "Patches/bun/pr5-ohos-runtime/CommandLineArguments.rs.patch"
  end
  patch :p1 do
    # linkat EEXIST retry + EPERM/EACCES fallback to copy install (OHOS SELinux)
    file "Patches/bun/pr5-ohos-runtime/PackageInstall.rs.patch"
  end
  patch :p1 do
    # After installing packages on OHOS, scan .so/.node and invoke binary-sign-tool for signing
    file "Patches/bun/pr5-ohos-runtime/PackageInstaller.rs.patch"
  end
  patch :p1 do
    # OHOS node-gyp temp scripts switch to /system/bin/sh (same as Android)
    file "Patches/bun/pr5-ohos-runtime/PackageManager.rs.patch"
  end
  patch :p1 do
    # symlinkat EPERM/EACCES retries after creating parent dir; split out ENOENT for separate handling
    file "Patches/bun/pr5-ohos-runtime/TarballStream.rs.patch"
  end
  patch :p1 do
    # linkat EPERM/EACCES multi-level fallback to copy (OHOS SELinux forbids hard links)
    file "Patches/bun/pr5-ohos-runtime/Hardlinker.rs.patch"
  end
  patch :p1 do
    # OHOS prepends cd to lifecycle scripts (avoids hmdfs getcwd failure causing shell exit)
    file "Patches/bun/pr5-ohos-runtime/lifecycle_script_runner.rs.patch"
  end
  patch :p1 do
    # npm cache linkat: on 3rd failure switch to copying contents (OHOS SELinux EPERM)
    file "Patches/bun/pr5-ohos-runtime/npm.rs.patch"
  end
  patch :p1 do
    # Add OPENHARMONY variant to OperatingSystem enum plus CURRENT and name table
    file "Patches/bun/pr5-ohos-runtime/resolver_hooks.rs.patch"
  end
  patch :p1 do
    # os.type/arch classifies openharmony as Linux; arm64 returns aarch64 (aligning with Android)
    file "Patches/bun/pr5-ohos-runtime/os.ts.patch"
  end
  patch :p1 do
    # OHOS switches to fork (seccomp forbids vfork); exit_group falls back to _exit; CLOEXEC fd floor raised to 2
    file "Patches/bun/pr5-ohos-runtime/bun-spawn.cpp.patch"
  end
  patch :p1 do
    # OHOS disables close_range (returns ENOSYS); installs SIGSYS handler; adds /system/bin to PATH
    file "Patches/bun/pr5-ohos-runtime/c-bindings.cpp.patch"
  end
  patch :p1 do
    # Codegen outputs "openharmony" for platform on OHOS
    file "Patches/bun/pr5-ohos-runtime/codegen.ts.patch"
  end
  # The pr5 version of compile_target.rs is already merged into the pr4
  # patch of the same name; no separate apply needed
  patch :p1 do
    # /tmp read-only falls back to /data/local/tmp/$HOME/tmp; RLIMIT_NOFILE minimum value; EACCES treated as missing
    file "Patches/bun/pr5-ohos-runtime/fs.rs.patch"
  end
  patch :p1 do
    # EACCES/EPERM skips ancestor dirs or treats them as missing (OHOS sandbox: "/","/storage" unreadable)
    file "Patches/bun/pr5-ohos-runtime/resolver.rs.patch"
  end
  patch :p1 do
    # openpty dlopen adds libc.so name and RTLD_DEFAULT fallback (OHOS openpty lives in libc)
    file "Patches/bun/pr5-ohos-runtime/Terminal.rs.patch"
  end
  patch :p1 do
    # OHOS disables can_use_memfd/use_memfd (same fstat-not-visible issue as spawn_process)
    file "Patches/bun/pr5-ohos-runtime/stdio.rs.patch"
  end
  patch :p1 do
    # OHOS no_orphans uses pidfd + 100ms polling to detect parent exit (signalfd hangs)
    file "Patches/bun/pr5-ohos-runtime/process.rs.patch"
  end
  patch :p1 do
    # OHOS disables the memfd stdio fast path (fstat returns size=0 after child writes);
    # also adds a shebang shim before posix_spawn_z: kernel exec rejects unsigned
    # shebang scripts (binary-sign-tool refuses non-ELF), so manually rewrite argv
    # to exec the already-signed interpreter with the script path as an argument.
    file "Patches/bun/pr5-ohos-runtime/spawn_process.rs.patch"
  end
  patch :p1 do
    # OHOS parses ELF SHT to locate the .bun section; ftruncate+fsync prevents COW write loss
    file "Patches/bun/pr5-ohos-runtime/StandaloneModuleGraph.rs.patch"
  end
  patch :p1 do
    # OHOS SELinux rejects linkat/symlinkat → add a copy_file_fallback content-copy path,
    # and add an OHOS tmpdir branch (shared by Hardlinker/PackageInstall/TarballStream)
    file "Patches/bun/pr5-ohos-runtime/install-lib.rs.patch"
  end
  # Not a standalone OHOS change — adds the filename to the npm manifest
  # invalid error message (general debug improvement)
  patch :p1 do
    file "Patches/bun/pr8-upstream-sync/npm_jsc-error-msg.patch"
  end
  patch :p1 do
    # OHOS resolver entry: short-circuit fs/deps/import-mapper
    file "Patches/bun/pr5-ohos-runtime/resolver-lib.rs.patch"
  end
  patch :p1 do
    # P0 epoll_pwait2: OHOS seccomp SECCOMP_RET_TRAP → SIGSYS kills the process outright,
    # so the upstream ENOSYS/EPERM/EACCES fallback chain never triggers. Force has_epoll_pwait2=0
    # to skip the first attempt and go straight to epoll_pwait (millisecond precision).
    # Lose nanosecond-granularity timeouts to stay alive.
    # Preflight probe c13_epoll_pwait2.
    file "Patches/bun/pr5-ohos-runtime/epoll_kqueue.c.patch"
  end
  patch :p1 do
    # OHOS openat2 returns ENOSYS directly (seccomp SIGSYS); loosen visibility of several fns
    file "Patches/bun/pr5-ohos-runtime/linux_syscall.rs.patch"
  end
  # pr6-rust-compat: Rust nightly toolchain compatibility fixes
  # (unrelated to OHOS, can be pushed upstream independently)
  patch :p1 do
    # errno → ExitCode now uses unsigned_abs() (nightly type change)
    file "Patches/bun/pr6-rust-compat/echo.rs.patch"
  end
  patch :p1 do
    # errno → ExitCode now uses unsigned_abs() (same as echo.rs)
    file "Patches/bun/pr6-rust-compat/which.rs.patch"
  end
  # pr7-shared-cfg-gate: cfg gate extensions for the shared musl/OHOS code path (OHOS libc is musl-derived)
  patch :p1 do
    # crash_handler musl gate extended to ohos; crash header libc label outputs "ohos (musl)"
    file "Patches/bun/pr7-shared-cfg-gate/lib.rs.patch"
  end
  patch :p1 do
    # Exclude v8 platform API block on OHOS (routes through the musl avoidance path; avoids smoke relocation fatal)
    file "Patches/bun/pr7-shared-cfg-gate/napi_body.rs.patch"
  end
  patch :p1 do
    # Extend setjmp/longjmp musl path to ohos; jmp_buf shrunk to 32×u64
    file "Patches/bun/pr7-shared-cfg-gate/recover.rs.patch"
  end

  def install
    # buildpath = bun source root (patches already auto-applied by Homebrew).
    # Build logic is fully inlined (mirroring git.rb in harmonybrew core — no external scripts).
    # All dependencies are declared via depends_on: llvm@21 (signing clang/lld), icu4c@78,
    # bun-webkit (JSC static libs), bun-bootstrap (L3 driver, bootstrap).

    # ── Vendor patches (not applied via git apply; applied by ninja to vendored crates during build) ──
    tap_patches = Pathname.new(__dir__)/"../../Patches/bun/pr3-vendor"
    (buildpath/"patches/lolhtml").mkpath
    (buildpath/"patches/zstd").mkpath
    cp tap_patches/"crate-type.patch", buildpath/"patches/lolhtml/crate-type.patch"
    cp tap_patches/"ohos-qsort-r.patch", buildpath/"patches/zstd/ohos-qsort-r.patch"

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

    # ── bun install (updates lockfile because package.json.patch modified devDependencies) ──
    # package.json.patch only changes build-essential items (esbuild version, ohos-signpost, postinstall),
    # so --ignore-scripts is not needed.
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    system "bun", "install"

    # ── Rust nightly (installed into buildpath, build-time only. Not included in bottle) ──
    # OHOS is a Tier 3 target: bun uses -Zbuild-std to build std, which requires rust-src (in full tarball).
    rust_home = buildpath/"rust-nightly"
    rust_home.mkpath
    resource("rust-nightly").stage do
      # The host tarball contains rustc/cargo/rust-std; install into rust_home via install.sh.
      # On OHOS the bash path is not in the superenv PATH, so run via sh to bypass the shebang dependency.
      system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end
    resource("rust-src").stage do
      # rust-src is a standalone target-agnostic tarball; bun -Zbuild-std needs library/Cargo.lock.
      system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end

    # ── Sign the rust binaries (OHOS kernel refuses to exec unsigned ELF, otherwise cargo reports 127) ──
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
      mv -f "$out" "$tmp"
      if "#{Formula["ohos-sdk"].opt_bin}/binary-sign-tool" sign -selfSign 1 -inFile "$tmp" -outFile "$out" >/dev/null 2>&1; then
        chmod +x "$out"
        # OHOS/tmpfs race: cargo build-script exec right after signing hits ETXTBSY
        # (kernel still sees stale writable fd reference). Force flush + brief settle.
        sync
        rm -f "$tmp"
      else
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
