class BunAT14 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  # Upstream oven-sh/bun has no OpenHarmony build target; this formula tracks
  # social4hyq/ohos-bun's ohos-aarch64 branch (OHOS patches merged from
  # upstream stable tags). See openspec/specs/bun-upstream-bridge.md for the
  # bridge policy — fork-as-bridge is the long-term shape, not a stopgap.
  url "https://github.com/social4hyq/ohos-bun.git", revision: "36854e8e5bb06809fe6e669679d21aae5823e8a0", branch: "ohos-aarch64"
  version "1.4.2"
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

  livecheck do
    url :stable
    regex(/^bun-v?(1\.4(?:\.\d+)*)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun@1.4-v1.4.2-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70592e128c592697b753091082a511ea25aab950c3c4e955c7665d79b32f71e0"
  end

  keg_only :versioned_formula

  depends_on "bun-bootstrap" => :build # Bootstrap: `bun bd` itself is a bun script
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "libxml2" => :build # lld link step for WebKit's nested-cmake build (see bun-webkit.rb history)
  # lld@21/llvm@21 resolve to harmonybrew/core (this tap's fork was retired
  # once upstreamed). lld@21 provides the --code-sign-by-default ld.lld
  # (split out of llvm@21); both are wired up directly in install() below
  # (no global cc/c++ shim).
  depends_on "lld@21" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  # only build-time rust-nightly cargo links libssl/libcrypto
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "zlib-ng-compat" => :build
  depends_on "node"
  # No runtime ohos-compat-shim dependency: vendored copy statically linked
  # into the executable AND every `bun build --compile` output. ohos-sdk is
  # build-time only: signs rust-nightly, clang-sign wrapper, and final binary.
  #
  # WebKit is built from source in install() (--webkit=local, matching
  # upstream's fetch_webkit) instead of consuming a separate bun-webkit
  # formula: bun's own scripts/build/deps/webkit.ts already wires OHOS
  # cross-compilation for local-mode's nested cmake build (reads the same
  # ohos-cross-libs/ohos-icu scaffold + CC/CXX this install() sets up for
  # the main build), so no bun-side scaffolding is needed beyond that.

  fails_with :gcc do
    cause "uses clang-specific flags"
  end

  # Rust nightly: OHOS is Tier 3 (no prebuilt rust-std), uses -Zbuild-std.
  # No "rustup" build dep (unlike upstream): OHOS's nightly target isn't in
  # rustup's channel manifest, only published as a static.rust-lang.org
  # tarball — same artifact rustup would fetch if it could resolve the
  # target at all. Version aligned with bun-src/rust-toolchain.toml.
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
    lld      = Formula["lld@21"]
    boot     = Formula["bun-bootstrap"]

    # Release SOP drift guard (openspec/specs/bun-upstream-bridge.md step 3):
    # fail the build instead of silently drifting if a merge forgot to bump
    # the rust-nightly resource.
    rust_toolchain_channel = (buildpath/"rust-toolchain.toml").read[/channel\s*=\s*"([^"]+)"/, 1]
    if rust_toolchain_channel != resource("rust-nightly").version.to_s
      odie "rust-toolchain.toml channel (#{rust_toolchain_channel}) != rust-nightly resource " \
           "(#{resource("rust-nightly").version}) — bump the resource or re-check the merge"
    end

    # WebKit built from source (--webkit=local below), matching upstream's
    # fetch_webkit: a full clone of oven-sh/WebKit is ~18GB and Homebrew's
    # unpack strategy would duplicate a `resource` block's download, so
    # shallow-clone the pinned autobuild tag directly instead.
    webkit_version = (buildpath/"scripts/build/deps/webkit.ts").read[/WEBKIT_VERSION = "(\h+)"/i, 1]
    clone_args = %W[
      --branch=autobuild-#{webkit_version}
      --config=advice.detachedHead=false
      --config=core.fsmonitor=false
      --depth=1
    ]
    system "git", "clone", *clone_args, "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"
    # Same fix upstream's bun.rb applies on Linux: a Homebrew-shimmed swiftc
    # found on PATH makes WebKit's cmake assume a real Swift toolchain is
    # present, misconfiguring the build. Strip the probe outright.
    inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
              "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""

    # Persistent build cache: brew's HOME is per-build .brew_home — cache would be wiped
    # each run and every vendor tarball re-downloaded. HOMEBREW_CACHE persists across runs.
    cache_dir = HOMEBREW_CACHE/"bun-build-cache"

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

    # lld from llvm@21 needs libxml2/zlib-ng-compat; cargo itself (the vendored
    # rust-nightly binary invoked below) also dynamically needs libz.so to run
    # at all -- zlib-ng-compat provides that (same soname/symbols as zlib).
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("libxml2").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zstd").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", llvm.opt_lib.to_s
    # openssl@3 provides libssl/libcrypto for rust cargo.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3").to_s
    # llvm@21 only ships llvm-strip; the bun build script needs strip.
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    # Scaffold ohos-cross-libs layout for bun's flags.ts.
    ohos_cross = buildpath/"build/ohos-cross-libs"
    (ohos_cross/"libcxx/include").mkpath
    (ohos_cross/"libcxxabi").mkpath
    # The flat host include dir, not include/aarch64-linux-ohos/c++/v1: see
    # the identical note in bun-webkit.rb's install() -- the target-triple
    # copy has its __has_include_next-chaining C-library wrapper headers
    # stripped, so a build that points -nostdinc++/-I straight at it alone
    # (as flags.ts does here) can't chain to the real musl headers. Host
    # and target headers are otherwise byte-identical.
    ln_sf llvm.opt_include/"c++/v1", ohos_cross/"libcxx/include/v1"
    ln_sf llvm.opt_include/"c++/v1", ohos_cross/"libcxxabi/include"
    # Each dir seeded with just its own archive; flags.ts links only -lc++ -lc++abi -lunwind.
    {
      "libcxx"    => "libc++.a",
      "libcxxabi" => "libc++abi.a",
      "libunwind" => "libunwind.a",
    }.each do |d, a|
      (ohos_cross/d/"lib").mkpath
      ln_sf llvm.opt_lib/"aarch64-linux-ohos"/a, ohos_cross/d/"lib"/a
    end
    # bootstrap bun in PATH: `bun bd` is itself a bun script.
    ENV.prepend_path "PATH", buildpath/".bin"
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    # lld@21's ld.lld carries the --code-sign-by-default patch (see lld@21.rb) —
    # it must come first on PATH so clang's driver (which resolves a bare
    # `ld.lld` via PATH, not via llvm@21's own bin/) finds *this* signed copy
    # instead of ohos-sdk's bundled unsigned fallback. No global shim needed:
    # CC/CXX below point straight at this keg's clang/clang++.
    ENV.prepend_path "PATH", lld.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    ENV.delete("RUSTC_WRAPPER")
    ca_bundle = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV["SSL_CERT_FILE"]  = ca_bundle.to_s
    ENV["CURL_CA_BUNDLE"] = ca_bundle.to_s
    ENV["RUSTUP_TOOLCHAIN"] = rust_ver
    ENV["OHOS_LLVM_PREFIX"] = llvm.opt_prefix.to_s
    ENV["OHOS_BUN_SIGNING_LINKER"] = (llvm.opt_bin/"clang++").to_s
    ENV["CC"]  = (llvm.opt_bin/"clang").to_s
    ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    # No CARGO_BUILD_JOBS cap: the old ETXTBSY came from the (now-removed)
    # global cc/c++ shims re-signing in-place; lld's --code-sign default
    # signs at link time only. Verified zero ETXTBSY in CI.
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"

    # ── Build: `bun run build:release` (upstream's package.json script name;
    # upstream itself invokes "build:release:local" — same script, difference
    # is only the --build-dir it hardcodes). Equivalent to the old direct
    # `bun scripts/build.ts --profile=release` call; `bun run` forwards
    # trailing flags to the script unchanged. --os=ohos --arch=aarch64
    # triggers the OHOS compile path in the bun source. --webkit=local makes
    # scripts/build/deps/webkit.ts nested-cmake-build the vendor/WebKit
    # clone above instead of requiring OHOS_WEBKIT_ROOT from a prebuilt
    # bun-webkit formula.
    sysroot = formula_opt_prefix("ohos-sdk")/"native/sysroot"
    # DEBUG (drop before merge): three earlier attempts (default buffered,
    # VERBOSE=1 + CMAKE_BUILD_PARALLEL_LEVEL=1, with_context(verbose: true))
    # all cut off at the *identical* byte position — right after WebKit
    # dep #521 ("Generating .../wtf/Hasher.h"), mid-write into #522 — with
    # nothing resembling ninja's usual multi-line "FAILED: <target>\n
    # <command>\n<stderr>" report in between. That rules out CI log
    # truncation (with_context's fork+pipe read loop prints line-by-line as
    # bytes arrive, uncapped) — the subprocess itself is not writing
    # anything more. Capture raw bytes ourselves into a file with no
    # buffering assumptions, and dump a large tail plus the byte/line count
    # on failure, so we can tell whether more content exists at all.
    require "open3"
    build_log = buildpath/"build-release-debug.log"
    args = [
      "bun", "run", "build:release",
      "--os=ohos", "--arch=aarch64", "--canary=off", "--webkit=local",
      "--cache-dir=#{cache_dir}",
      "--ohos-sdk-root=#{formula_opt_prefix("ohos-sdk")}",
      "--ohos-sysroot=#{sysroot}"
    ]
    status = File.open(build_log, "w") do |f|
      Open3.popen2e(*args, chdir: buildpath.to_s) do |stdin, out, wait_thr|
        stdin.close
        IO.copy_stream(out, f) # raw byte copy, no line-buffering assumptions
        wait_thr.value
      end
    end
    unless status.success?
      lines = File.readlines(build_log)
      puts "=== build-release-debug.log: #{lines.size} lines, #{File.size(build_log)} bytes ==="
      puts lines.last(500)
      # DEBUG (drop before merge): distinguish a clean nonzero exit from a
      # signal kill (e.g. OOM) — three prior attempts stopped mid-output
      # with zero diagnostic text regardless of verbosity/parallelism,
      # which only a signal death (no chance to print anything) explains.
      puts "=== process status: exited=#{status.exited?} exitstatus=#{status.exitstatus.inspect} " \
           "signaled=#{status.signaled?} termsig=#{status.termsig.inspect} ==="
      # DEBUG (drop before merge): $stdout is fully buffered when piped
      # (non-tty) — the 500-line dump above self-flushed by exceeding the
      # buffer repeatedly, but this short line alone won't, and odie's own
      # message goes through $stderr (unbuffered) and appeared even when
      # this one didn't in the previous attempt. Force it out explicitly.
      $stdout.flush
      odie "bun run build:release failed (see build-release-debug.log dump above)"
    end

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
    # the old keg (this shipped the r32 bottle without bin/bun, see bun.rb history).
    mkdir_p libexec/"bin"
    libexec.install out => "bin/bun" # mv preserves the 0755 set above
    bin.mkpath
    (bin/"bun").make_symlink "../libexec/bin/bun"
    (bin/"bunx").make_symlink "bun"

    # Static shell completions shipped in source tree.
    bash_completion.install "completions/bun.bash" => "bun"
    fish_completion.install "completions/bun.fish"
    zsh_completion.install "completions/bun.zsh" => "_bun"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bun --version")
    refute_match "canary", shell_output("#{bin}/bun --revision")

    system bin/"bun", "init", "--yes"
    assert_equal "Hello via Bun!", shell_output("#{bin}/bun run index.ts").chomp

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
