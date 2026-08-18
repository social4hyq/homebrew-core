class BunProbe < Formula
  desc "JavaScript runtime for HarmonyOS aarch64 (stable)"
  homepage "https://github.com/oven-sh/bun"
  # Fully rewritten from upstream: 50+ OHOS patches on ohos-aarch64 branch,
  # L4 self-bootstrap, pre-populated WebKit cache, Rust nightly -Zbuild-std.
  url "https://github.com/social4hyq/ohos-bun.git", revision: "7c72f345b248c38c5da583eaa802cc35d62c7dfc", branch: "diag-spin-probe"
  version "1.4.0"
  license "MIT"
  revision 62
  # head tracks the same pre-patched fork branch as url.
  head "https://github.com/social4hyq/ohos-bun.git", branch: "diag-spin-probe"

  livecheck do
    url :stable
    regex(/^bun-v?(\d+(?:\.\d+)+)$/i)
  end

  # icu4c@78 resolves to harmonybrew/core (this tap's __h fork was dropped in __n1 migration).
  depends_on "bun-bootstrap" => :build # Bootstrap: `bun bd` itself is a bun script
  depends_on "bun-webkit" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  # only build-time rust-nightly cargo links libssl/libcrypto
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "node"
  # No runtime ohos-compat-shim dependency since r31: vendored copy statically linked
  # into the executable AND every `bun build --compile` output. ohos-sdk is build-time
  # only: signs rust-nightly, clang-sign wrapper, and final binary.

  # Rust nightly: OHOS is Tier 3 (no prebuilt rust-std), uses -Zbuild-std.
  # Version aligned with bun-src/rust-toolchain.toml.
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-07-20/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    version "nightly-2026-07-20"
    sha256 "7d3dd4cc4f55ee8a7c7f09804b96fd52ef7ef598a935772091e80aa66869676e"
  end

  # rust-src required by -Zbuild-std.
  resource "rust-src" do
    url "https://static.rust-lang.org/dist/2026-07-20/rust-src-nightly.tar.gz"
    version "nightly-2026-07-20"
    sha256 "2be85b655b99624bed0fb63a47e564abac07aa1fb5d0576abac5c42ef8c5316e"
  end

  # OHOS patches pre-applied on ohos-aarch64 branch, kept in sync with upstream via merge.
  # Vendor patches committed directly in source tree.

  def install
    # buildpath = bun source root; build logic fully inlined — no external scripts.

    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    # Persistent build cache: brew's HOME is per-build .brew_home — cache would be wiped
    # each run and every vendor tarball re-downloaded. HOMEBREW_CACHE persists across runs.
    cache_dir = HOMEBREW_CACHE/"bun-build-cache"

    # Pre-populate WebKit cache from bun-webkit formula (single source of truth for the commit).
    # bun bd checks .identity to skip download.
    webkit_ver = webkit.stable.specs[:revision]
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
      ln_sf formula_opt_lib("icu4c@78")/a, wc/"lib"/a
    end

    # Scaffold build/ohos-icu layout for bun's config.ts (defaults to wrapper's build-icu.sh path).
    # Point at icu4c@78 formula instead.
    icu = Formula["icu4c@78"]
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

    # bun.lock on ohos-aarch64 branch matches package.json.
    # All packages pre-cached, no network access needed.
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    system "bun", "install"
    # node-fallbacks has its own bun.lock; pre-populate cache so ninja's
    # subsequent `bun install --frozen-lockfile` can verify without network.
    system "bun", "install", "--cwd", "src/node-fallbacks"

    rust_ver = resource("rust-nightly").version.to_s # e.g. "nightly-2026-07-20"
    # rust_home must stay on EL2 (exec'd after signing; EL3 hmmac refuses non-EL2 exec).
    rust_home = Pathname.new("/data/storage/el2/base/tmp/rust-#{rust_ver}")
    rust_ready = rust_home/"BREW_SIGNED_OK"

    # Shared mutable state: flock serializes concurrent brew sessions.
    rust_home.mkpath
    File.open(rust_home/".brew-install-lock", File::CREAT | File::RDWR) do |lock|
      lock.flock(File::LOCK_EX)
      unless rust_ready.exist?
        resource("rust-nightly").stage do
          # Use sh explicitly: OHOS superenv PATH has no bash for the shebang.
          system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
        end
        resource("rust-src").stage do
          system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
        end

        # Sign rust binaries (OHOS refuses to exec unsigned ELF).
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
    end

    # lld from llvm@21 needs libxml2/zlib; rust cargo needs libssl/libcrypto.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("libxml2").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib").to_s
    # openssl@3 provides libssl/libcrypto for rust cargo.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3").to_s
    # llvm@21 only ships llvm-strip; the bun build script needs strip.
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    # Scaffold ohos-cross-libs layout for bun's flags.ts.
    ohos_cross = buildpath/"build/ohos-cross-libs"
    (ohos_cross/"libcxx/include").mkpath
    (ohos_cross/"libcxxabi").mkpath
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxx/include/v1"
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxxabi/include"
    # Each dir seeded with just its own archive; flags.ts links only -lc++ -lc++abi -lunwind.
    {
      "libcxx"    => "libc++.a",
      "libcxxabi" => "libc++abi.a",
      "libunwind" => "libunwind.a",
    }.each do |d, a|
      (ohos_cross/d/"lib").mkpath
      ln_sf llvm.opt_lib/"aarch64-linux-ohos"/a, ohos_cross/d/"lib"/a
    end
    # llvm@21 cc/c++ shims wrap clang with LLD --code-sign (replaces legacy clang-sign wrapper).
    # bootstrap bun in PATH: `bun bd` is itself a bun script.
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
    ENV["RUSTUP_TOOLCHAIN"] = rust_ver
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s
    ENV["OHOS_BUN_SIGNING_LINKER"] = (HOMEBREW_PREFIX/"bin/c++").to_s
    ENV["CC"]  = (HOMEBREW_PREFIX/"bin/cc").to_s
    ENV["CXX"] = (HOMEBREW_PREFIX/"bin/c++").to_s
    # No CARGO_BUILD_JOBS cap: the old ETXTBSY came from cc/c++ shims re-signing in-place;
    # the shim now signs at link time only. Verified zero ETXTBSY in CI.
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
    # Sign bun binary (OHOS refuses to exec unsigned ELF).
    sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
    unsigned = "#{out}.unsigned"
    mv out, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", out
    chmod 0755, out
    rm unsigned
    # Relative symlink (not install_symlink): the latter realpaths through the previous
    # version's opt link during upgrades, producing a dangling symlink once cleanup removes
    # the old keg (this shipped the r32 bottle without bin/bun).
    mkdir_p libexec/"bin"
    libexec.install out => "bin/bun" # mv preserves the 0755 set above
    bin.mkpath
    (bin/"bun").make_symlink "../libexec/bin/bun"

    # Static shell completions shipped in source tree.
    bash_completion.install "completions/bun.bash" => "bun"
    fish_completion.install "completions/bun.fish"
    zsh_completion.install "completions/bun.zsh" => "_bun"
  end

  def post_install
    # Pre-cache node-gyp@11 so napi tests don't timeout on first download.
    # Brew sandbox TMPDIR has mismatched ownership; use EL2 tmp.
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

    # Regression test for r37: bun install must self-sign native .node files
    # (unsigned → ERR_DLOPEN_FAILED). Tests both hoisted and isolated linker layouts.
    shstrtab = "\0.text\0.shstrtab\0".b
    text_off = 64
    text_size = 16
    shstr_off = text_off + text_size
    sh_off = shstr_off + shstrtab.bytesize
    sh_off += (8 - (sh_off % 8)) % 8
    section = lambda do |name, type, offset, size, align|
      [name, type, 0, 0, offset, size, 0, 0, align, 0].pack("L<L<Q<Q<Q<Q<L<L<Q<Q<")
    end

    # ELF64 aarch64 ET_DYN with a three-entry section header table — the
    # minimum the signer parses and extends. Never dlopen'd by this test.
    elf = [0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0].pack("C8") + ("\0" * 8)
    elf += [3, 183, 1].pack("S<S<L<")                 # ET_DYN, EM_AARCH64, EV_CURRENT
    elf += [0, 0, sh_off, 0].pack("Q<Q<Q<L<")         # e_entry, e_phoff, e_shoff, e_flags
    elf += [64, 0, 0, 64, 3, 2].pack("S<S<S<S<S<S<")  # e_ehsize .. e_shstrndx
    elf += "\0" * text_size
    elf += shstrtab
    elf += "\0" * (sh_off - elf.bytesize)
    elf += section.call(0, 0, 0, 0, 0)                          # SHT_NULL
    elf += section.call(1, 1, text_off, text_size, 4)           # .text
    elf += section.call(7, 3, shstr_off, shstrtab.bytesize, 1)  # .shstrtab

    (testpath/"fixture").mkpath
    (testpath/"fixture/package.json").write <<~JSON
      {"name": "@fixture/native", "version": "1.0.0"}
    JSON
    (testpath/"fixture/binding.node").binwrite elf
    refute_includes (testpath/"fixture/binding.node").binread, ".codesign"

    cd testpath/"fixture" do
      system bin/"bun", "pm", "pack"
    end
    tarball = Pathname.new(Dir[testpath/"fixture/*.tgz"].fetch(0)).basename

    manifest = <<~JSON
      {"name": "app", "private": true,
       "dependencies": {"@fixture/native": "file:../fixture/#{tarball}"}}
    JSON

    (testpath/"app").mkpath
    (testpath/"app/package.json").write manifest
    cd testpath/"app" do
      system bin/"bun", "install"
    end

    installed = testpath/"app/node_modules/@fixture/native/binding.node"
    assert_path_exists installed
    refute_predicate installed, :symlink?
    assert_includes installed.binread, ".codesign"

    # Isolated linker: each package materialized once in .bun/ store. Must sign
    # store copies, not follow symlinks. FNM_DOTMATCH required for .bun dir.
    (testpath/"app-isolated").mkpath
    (testpath/"app-isolated/package.json").write manifest
    cd testpath/"app-isolated" do
      system bin/"bun", "install", "--linker", "isolated"
    end

    store_copies = Dir.glob(
      testpath/"app-isolated/node_modules/**/binding.node",
      File::FNM_DOTMATCH,
    )
    refute_empty store_copies
    store_copies.each do |copy|
      assert_includes File.binread(copy), ".codesign"
    end
  end
end
