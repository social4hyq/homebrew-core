class BunCanary < Formula
  desc "Bun — JavaScript runtime for HarmonyOS aarch64 (canary, rolling)"
  homepage "https://github.com/oven-sh/bun"
  url "https://github.com/oven-sh/bun.git", branch: "canary"
  version "1.4.0-a4cd4d2"
  license "MIT"
  head "https://github.com/oven-sh/bun.git", branch: "canary"

  livecheck do
    url "https://github.com/oven-sh/bun/releases/latest"
    regex(/bun-v?canary\.?(.+)/i)
  end

  # bottle: not yet built, use build-from-source for now. Uncomment when bottle is published.
  #   bottle do
  #     root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-canary-v1.4.0-a4cd4d2"
  # sha256 cellar: :any_skip_relocation, arm64_ohos: "<fill-after-bottle-build>"
  # end

  keg_only "canary build; use `bun` for the stable command"

  depends_on "bun-bootstrap" => :build
  depends_on "cmake"          => :build
  depends_on "gperf"          => :build
  depends_on "llvm@21" => :build
  depends_on "ninja"          => :build
  depends_on "perl"           => :build
  depends_on "python@3.14"    => :build
  depends_on "ruby"           => :build
  depends_on "bun-webkit"
  depends_on "icu4c@78"
  depends_on "ohos-sdk"

  # Rust nightly (native OHOS host toolchain, same as bun.rb)
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    version "nightly-2026-05-06"
    sha256 "7e93009ca8eb40fa039ba7fce6d8d6e95646b6459a7582e4ea46308c7db00eb8"
  end

  # ── OHOS patches (mirroring git.rb's patch do file pattern) ──
  # Homebrew auto-applies them to buildpath (= bun source root) before def install.
  # Declared in PR order (pr3 → pr7, order-sensitive).
  # Each patch must have a comment explaining its purpose and upstream issue (Homebrew audit requirement).
  patch :p1 do
    # pr3-vendor: change lolhtml crate-type to staticlib (OHOS has no dynamic linking support)
    file "Patches/bun/pr3-vendor/crate-type.patch"
  end
  patch :p1 do
    # pr3-vendor: zstd qsort_r not available on OHOS musl
    file "Patches/bun/pr3-vendor/ohos-qsort-r.patch"
  end
  patch :p1 do
    # pr3-vendor: OHOS adaptation for zstd dep build script
    file "Patches/bun/pr3-vendor/zstd.ts.patch"
  end
  # pr4-build-target: OHOS cross-compilation target support (OS="ohos", triple, sysroot/SDK config)
  patch :p1 do
    # build.ts: add --ohos-sysroot / --ohos-sdk-root CLI options
    file "Patches/bun/pr4-build-target/build.ts.patch"
  end
  patch :p1 do
    # OHOS: link libc/pthread/dl and local WebKit ICU, skip smoke tests during cross-compile
    file "Patches/bun/pr4-build-target/bun.ts.patch"
  end
  patch :p1 do
    # OHOS musl lacks GNU extensions (memmem/getservbyport_r), exclude in c-ares config.h
    file "Patches/bun/pr4-build-target/cares.ts.patch"
  end
  patch :p1 do
    # Add OS="ohos", hostCc field and sysroot/SDK/cross-libs/ICU cross-compilation config
    file "Patches/bun/pr4-build-target/config.ts.patch"
  end
  patch :p1 do
    # OHOS compile/link flags: triple, sysroot, libc++, PIE, 8MB stack, skip zstd debug
    file "Patches/bun/pr4-build-target/flags.ts.patch"
  end
  patch :p1 do
    # OHOS: also disable MI_NO_SET_VMA_NAME (VMA label debug sugar)
    file "Patches/bun/pr4-build-target/mimalloc.ts.patch"
  end
  patch :p1 do
    # Add aarch64-unknown-linux-ohos target, linker can go through signed wrapper
    file "Patches/bun/pr4-build-target/rust.ts.patch"
  end
  patch :p1 do
    # dep_host_cc: chain binary-sign-tool after link for signing, OHOS native cargo uses signed linker
    file "Patches/bun/pr4-build-target/source.ts.patch"
  end
  patch :p1 do
    # Relax LLVM version range to 21–23, add OHOS LLVM22 search path and install hint
    file "Patches/bun/pr4-build-target/tools.ts.patch"
  end
  patch :p1 do
    # Add OHOS prebuilt/ICU selection and cross-compilation CMake config (sysroot, libc++ headers, ICU tools)
    file "Patches/bun/pr4-build-target/webkit.ts.patch"
  end
  patch :p1 do
    # tmpdir() prefers $TMPDIR, adapt to OHOS read-only /tmp (erofs)
    file "Patches/bun/pr4-build-target/utils.mjs.patch"
  end
  patch :p1 do
    # Add ohos-signpost dep and postinstall probe hook (backfill detect-libc and other deps)
    file "Patches/bun/pr4-build-target/package.json.patch"
  end
  patch :p1 do
    # Add Libc::Ohos enum and triple parsing, platform string reports "ohos", support file:// registration
    file "Patches/bun/pr4-build-target/compile_target.rs.patch"
  end
  patch :p1 do
    # bun upgrade download suffix for OHOS uses -ohos (new branch beyond musl/android)
    file "Patches/bun/pr4-build-target/upgrade_command.rs.patch"
  end
  # pr5-ohos-runtime: OHOS-specific runtime substitutions
  # (syscall fallbacks, vfork→fork, signing, platform=openharmony)
  patch :p1 do
    # OHOS: process.platform returns "openharmony" (align with Node naming)
    file "Patches/bun/pr5-ohos-runtime/BunProcess.cpp.patch"
  end
  patch :p1 do
    # OHOS: external OS name maps to openharmony/OpenHarmony (so optional deps resolve correctly)
    file "Patches/bun/pr5-ohos-runtime/Global.rs.patch"
  end
  patch :p1 do
    # Add IS_OHOS / IS_GLIBC; IS_MUSL counts ohos in as well
    file "Patches/bun/pr5-ohos-runtime/env.rs.patch"
  end
  patch :p1 do
    # OHOS: skip fchmodat2, getcwd falls back to "/", call signing tool before dlopen
    file "Patches/bun/pr5-ohos-runtime/lib.rs.patch"
  end
  patch :p1 do
    # OHOS: call binary-sign-tool to sign build output and chmod 755 (seccomp requirement)
    file "Patches/bun/pr5-ohos-runtime/build_command.rs.patch"
  end
  patch :p1 do
    # OHOS: set $PWD, mark pipe as socket + non-blocking to avoid blocking infinite loop
    file "Patches/bun/pr5-ohos-runtime/filter_run.rs.patch"
  end
  patch :p1 do
    # OHOS: set $PWD (bash uses stat instead of getcwd), silently swallow CWD EPERM and fall back to $HOME
    file "Patches/bun/pr5-ohos-runtime/run_command.rs.patch"
  end
  patch :p1 do
    # pm scan: add openharmony to the list of valid OSes
    file "Patches/bun/pr5-ohos-runtime/CommandLineArguments.rs.patch"
  end
  patch :p1 do
    # linkat EEXIST retry + EPERM/EACCES failure falls back to copy install (OHOS SELinux)
    file "Patches/bun/pr5-ohos-runtime/PackageInstall.rs.patch"
  end
  patch :p1 do
    # OHOS: after installing packages, scan .so/.node and call binary-sign-tool to sign
    file "Patches/bun/pr5-ohos-runtime/PackageInstaller.rs.patch"
  end
  patch :p1 do
    # OHOS: node-gyp temp scripts use /system/bin/sh (same as Android)
    file "Patches/bun/pr5-ohos-runtime/PackageManager.rs.patch"
  end
  patch :p1 do
    # symlinkat EPERM/EACCES: retry after creating parent dir; split out ENOENT for separate handling
    file "Patches/bun/pr5-ohos-runtime/TarballStream.rs.patch"
  end
  patch :p1 do
    # linkat EPERM/EACCES: multi-level fallback to copy (OHOS SELinux forbids hardlinks)
    file "Patches/bun/pr5-ohos-runtime/Hardlinker.rs.patch"
  end
  patch :p1 do
    # OHOS: insert cd before lifecycle scripts (avoid hmdfs getcwd failure causing shell to exit)
    file "Patches/bun/pr5-ohos-runtime/lifecycle_script_runner.rs.patch"
  end
  patch :p1 do
    # npm cache linkat: on 3rd failure, copy contents instead (OHOS SELinux EPERM)
    file "Patches/bun/pr5-ohos-runtime/npm.rs.patch"
  end
  patch :p1 do
    # OperatingSystem enum: add OPENHARMONY variant plus CURRENT and name table
    file "Patches/bun/pr5-ohos-runtime/resolver_hooks.rs.patch"
  end
  patch :p1 do
    # os.type/arch: classify openharmony as Linux, arm64 returns aarch64 (align with Android)
    file "Patches/bun/pr5-ohos-runtime/os.ts.patch"
  end
  patch :p1 do
    # OHOS: switch to fork (seccomp forbids vfork), exit_group falls back to _exit, raise CLOEXEC fd lower bound to 2
    file "Patches/bun/pr5-ohos-runtime/bun-spawn.cpp.patch"
  end
  patch :p1 do
    # OHOS: disable close_range (returns ENOSYS), install SIGSYS handler, add /system/bin to PATH
    file "Patches/bun/pr5-ohos-runtime/c-bindings.cpp.patch"
  end
  patch :p1 do
    # Code generation: platform outputs "openharmony" for OHOS
    file "Patches/bun/pr5-ohos-runtime/codegen.ts.patch"
  end
  patch :p1 do
    # pr5 version: Libc::Ohos platform string now uses "openharmony" (overrides pr4, aligns with Node)
    file "Patches/bun/pr5-ohos-runtime/compile_target.rs.patch"
  end
  patch :p1 do
    # /tmp read-only: fall back to /data/local/tmp/$HOME/tmp, RLIMIT_NOFILE minimum, treat EACCES as missing
    file "Patches/bun/pr5-ohos-runtime/fs.rs.patch"
  end
  patch :p1 do
    # EACCES/EPERM: skip ancestor dirs or treat as missing (OHOS sandbox: "/", "/storage" unreadable)
    file "Patches/bun/pr5-ohos-runtime/resolver.rs.patch"
  end
  patch :p1 do
    # openpty dlopen: add libc.so name and RTLD_DEFAULT fallback (OHOS openpty lives in libc)
    file "Patches/bun/pr5-ohos-runtime/Terminal.rs.patch"
  end
  patch :p1 do
    # OHOS: disable can_use_memfd/use_memfd (same fstat invisibility issue as spawn_process)
    file "Patches/bun/pr5-ohos-runtime/stdio.rs.patch"
  end
  patch :p1 do
    # OHOS: no_orphans uses pidfd + 100ms polling to detect parent exit (signalfd hangs)
    file "Patches/bun/pr5-ohos-runtime/process.rs.patch"
  end
  patch :p1 do
    # OHOS: disable memfd stdio fast path (child writes, fstat reports size=0)
    file "Patches/bun/pr5-ohos-runtime/spawn_process.rs.patch"
  end
  patch :p1 do
    # OHOS: parse ELF SHT to locate .bun section, ftruncate+fsync to prevent COW write loss
    file "Patches/bun/pr5-ohos-runtime/StandaloneModuleGraph.rs.patch"
  end
  patch :p1 do
    # OHOS: openat2 returns ENOSYS directly (seccomp SIGSYS), relax visibility of several fns
    file "Patches/bun/pr5-ohos-runtime/linux_syscall.rs.patch"
  end
  # pr6-rust-compat: Rust nightly toolchain compatibility fixes (OHOS-independent, can be pushed upstream standalone)
  patch :p1 do
    # Adapt to nightly: Type::info().size becomes Type::size().expect()
    file "Patches/bun/pr6-rust-compat/multi_array_list.rs.patch"
  end
  patch :p1 do
    # errno to ExitCode conversion now uses unsigned_abs() (nightly type change)
    file "Patches/bun/pr6-rust-compat/echo.rs.patch"
  end
  patch :p1 do
    # errno to ExitCode conversion now uses unsigned_abs() (same as echo.rs)
    file "Patches/bun/pr6-rust-compat/which.rs.patch"
  end
  # pr7-shared-cfg-gate: shared musl/OHOS code path cfg gate extensions (OHOS libc is musl-derived)
  patch :p1 do
    # crash_handler: extend musl gate to ohos, crash header libc label outputs "ohos (musl)"
    file "Patches/bun/pr7-shared-cfg-gate/lib.rs.patch"
  end
  patch :p1 do
    # Exclude v8 platform API block for OHOS (let it take musl workaround path, avoid smoke relocation fatal)
    file "Patches/bun/pr7-shared-cfg-gate/napi_body.rs.patch"
  end
  patch :p1 do
    # Extend setjmp/longjmp musl path to ohos, shrink jmp_buf to 32×u64
    file "Patches/bun/pr7-shared-cfg-gate/recover.rs.patch"
  end

  def install
    # Build logic inlined (same as bun.rb, only differs in --canary=on + installed as bun-canary).
    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    rust_home = libexec/"rust-nightly"
    rust_home.mkpath
    resource("rust-nightly").stage do
      system "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end

    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    ENV["RUSTUP_TOOLCHAIN"] = "nightly-2026-05-06"
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s

    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=on"

    out = buildpath/"build/release/bun-release"
    odie "bun binary missing after build: #{out}" unless out.exist?
    bin.install out => "bun-canary"
  end

  def caveats
    <<~EOS
      Bun canary (#{version}) for HarmonyOS aarch64.
      Rolling canary build — keg-only, provides `bun-canary`.
      For the stable command, install `bun` instead.
      Note: canary does NOT graduate to harmonybrew/core.
    EOS
  end

  test do
    assert_match "4294967296", shell_output("#{bin}/bun-canary -e 'console.log(2**32)'")
  end
end
