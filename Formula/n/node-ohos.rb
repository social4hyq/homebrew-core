class NodeOhos < Formula
  desc "Node.js, built with llvm@21 for libc++ ABI compatibility with bun/nan addons"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v26.7.0/node-v26.7.0.tar.xz"
  sha256 "e6b182cbeeab032d1082ca4ac4fe15e3a57de691d3bde78ecf8a761fd56ee356"
  license "MIT"

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  keg_only "alternate toolchain build of node; the harmonybrew/core node formula " \
           "is the default for general use"

  # Compiler toolchain — see the long comment in install() for why this
  # exists at all.
  depends_on "llvm@21" => :build
  depends_on "ohos-sdk" => :build
  depends_on "python@3.14" => :build

  # We track major/minor from upstream Node releases, same as upstream's own
  # node.rb — the version bundled in deps/npm is intentionally not used
  # (--without-npm below).
  resource "npm" do
    url "https://registry.npmjs.org/npm/-/npm-11.19.0.tgz"
    sha256 "31e9770f7dc71119a58509353b27917557aaf0ac9b5ef1a0465ee7d8ec67ae75"

    livecheck do
      url "https://raw.githubusercontent.com/nodejs/node/refs/tags/v#{LATEST_VERSION}/deps/npm/package.json"
      strategy :json do |json|
        json["version"]
      end
    end
  end

  deny_network_access! [:build, :postinstall]

  def install
    # harmonybrew/core's node formula builds Node.js/V8 in an Alpine Linux
    # chroot with Alpine's native GCC, statically linking GNU libstdc++ —
    # a workaround for the OHOS SDK's bundled clang 15 being too old to
    # compile Node 26, predating this tap's own llvm@21. That produces a
    # binary whose exported v8:: symbols mangle with GNU libstdc++'s ABI
    # (plain std::optional<...>, no inline namespace), permanently
    # incompatible with nan/node-gyp addons built against llvm@21's libc++
    # (std::__n1::optional<...>) — including addons that work fine under
    # bun, which already links llvm@21. Building node itself against
    # llvm@21 fixes both problems at once: llvm@21 has the C++20 stdlib
    # pieces (e.g. <source_location>) the OHOS SDK clang lacks, and its
    # exported symbols match what llvm@21-built native addons expect.
    #
    # Verified on real hardware: full build compiles clean, passes this
    # formula's own smoke tests (console.log, ICU/Intl, WASI), and a
    # nan-style addon (@datadog/pprof) dlopens and profiles real data
    # against this build with no manual LD_PRELOAD needed by the caller.
    llvm = Formula["llvm@21"]
    ENV["CC"]  = (llvm.opt_bin/"clang").to_s
    ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    # gyp's static_library rule shells out to a bare `ar`; superenv's
    # restricted build PATH doesn't provide one (llvm@21 only ships the
    # real name `llvm-ar`, not an `ar` alias).
    ENV["AR"] = (llvm.opt_bin/"llvm-ar").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", llvm.opt_lib

    # make sure subprocesses spawned by make are using our Python 3
    ENV["PYTHON"] = which("python3.14")

    # Only drop deps/npm — deps/icu-small is kept. Despite the legacy
    # name, node's official release tarballs have shipped *full* ICU data
    # there for years (confirmed: 34MB, marked by
    # deps/icu-small/README-FULL-ICU.txt), and --with-intl defaults to
    # full-icu using exactly that canned copy when no other ICU source is
    # given — no network access needed, no external ICU dependency
    # needed. An earlier version of this formula deleted deps/icu-small
    # and linked against a formula-provided icu4c@78 instead
    # (--with-intl=system-icu), which needed its own LD_PRELOAD wrapper
    # (see the devendoring comment on ignored_shared_flags below for why)
    # — entirely self-inflicted, once it turned out the bundled copy
    # already did the job.
    rm_r("deps/npm")

    # Never install the bundled "npm", always prefer our installation from
    # tarball for better packaging control.
    # No --openssl-use-def-ca-store: that flag makes node look for a CA
    # bundle at OpenSSL's compiled-in *system* path at runtime, which
    # isn't reliably populated on this platform — CI failed with
    # "UNABLE_TO_GET_ISSUER_CERT_LOCALLY" the one time this was tried
    # (npm install couldn't TLS-verify registry.npmjs.org). Omitting the
    # flag falls back to node's default: a Mozilla CA bundle compiled
    # directly into the binary, so there's no runtime file to be missing.
    # harmonybrew/core's own node/node@22/node@24 formulas don't pass any
    # openssl/CA flag either, for the same reason.
    args = %W[
      --prefix=#{prefix}
      --dest-os=openharmony
      --without-npm
      --shared
      --disable-single-executable-application
    ]

    # An earlier version of this formula devendored every one of node's
    # optional deps (--shared-uv, --shared-openssl, --shared-brotli, ...)
    # against formula-provided copies, mirroring upstream
    # Homebrew/homebrew-core's own node.rb. That turned out to be the
    # wrong call for *this* formula specifically: OHOS's dlopen() puts
    # every loaded module in its own linker namespace, so a nan/node-gyp
    # addon loaded via require() can't resolve symbols back into any
    # already-loaded library unless that specific library was itself
    # linked with -Wl,-z,global (DF_1_GLOBAL) — true not just for
    # libnode.so (fixed via common.gypi below) but for every one of those
    # devendored .so's too. We can add that flag to libnode.so's own
    # build, but not to harmonybrew/core's independently-built
    # libuv/brotli/etc. bottles without rebuilding them ourselves.
    # Verified on real hardware: a nan-based addon (@datadog/pprof) failed
    # to dlopen on uv_async_init — from libuv, one of these devendored
    # deps — even with libnode.so correctly marked global.
    #
    # harmonybrew/core's own node/node@22/node@24 formulas independently
    # arrived at the same answer: none of them devendor anything either
    # (zero `depends_on` beyond their Alpine chroot build tools, plain
    # `--partly-static`). So none of node's deps are devendored here: without
    # a --shared-* flag they compile from node's own bundled deps/ sources
    # straight into libnode.so, inheriting its -Wl,-z,global instead of
    # needing their own.
    ignored_shared_flags = %w[
      ada
      brotli
      cares
      ffi
      gtest
      hdr-histogram
      http-parser
      lief
      libuv
      merve
      nbytes
      nghttp2
      nghttp3
      ngtcp2
      openssl
      simdjson
      simdutf
      sqlite
      temporal_capi
      uvwasi
      zlib
      zstd
    ].map { |library| "--shared-#{library}" }

    configure_help = Utils.safe_popen_read("./configure", "--help")
    shared_flag_regex = /\[(--shared-[^ \]]+)\]/
    configure_help.scan(shared_flag_regex) do |matches|
      matches.each do |flag|
        next if args.include?(flag) || ignored_shared_flags.include?(flag)

        odie "Unused `--shared-*` flag: #{flag}"
      end
    end

    # OHOS's dlopen() puts every loaded module in its own linker namespace,
    # so a nan/node-gyp addon loaded via require() can't resolve symbols
    # back into libnode.so unless it was itself linked with -Wl,-z,global
    # (DF_1_GLOBAL) — otherwise every such addon fails with "Error
    # relocating ...: symbol not found" for perfectly-exported symbols
    # like node::AddEnvironmentCleanupHook. This is threaded through to
    # common.gypi rather than set via ENV["LDFLAGS"], because that's the
    # only place a flag reliably reaches the *final* link step here:
    # CC/CXX above are absolute paths to llvm@21 (to sidestep Homebrew's
    # CompilerSelectionError, which only recognizes a bare `clang` on
    # PATH), so `make` invokes the compiler directly and never goes
    # through this tap's superenv shim — an ENV.append "LDFLAGS" would
    # never reach the link command, and node's own configure.py doesn't
    # read $LDFLAGS either. harmonybrew/core's own python@3.12/3.13/3.14
    # and zsh formulas rely on the same flag for the same reason (their
    # own dlopen'd C-extension/module loaders), just via a plain LDFLAGS
    # append since their build systems do read it.
    inreplace "common.gypi" do |s|
      s.sub!(
        "'ldflags': [ '-rdynamic' ],",
        "'ldflags': [ '-rdynamic', '-Wl,-z,global' ],",
      ) || odie("node-ohos: common.gypi OS-conditional ldflags anchor not found")
    end

    system "./configure", *args
    system "make", "install"

    # Allow npm to find Node before installation has completed.
    ENV.prepend_path "PATH", bin

    bootstrap = buildpath/"npm_bootstrap"
    bootstrap.install resource("npm")
    # These dirs must exist before npm install.
    (libexec/"lib").mkpath
    system "node", bootstrap/"bin/npm-cli.js", "install", "--loglevel=silly", "--global",
            "--prefix=#{libexec}", resource("npm").cached_download

    # The `package.json` stores integrity information about the above
    # passed-in `cached_download` npm resource, which breaks
    # `npm -g outdated npm`. This copies back over the vanilla
    # `package.json` to fix this issue.
    (libexec/"lib/node_modules/npm").install bootstrap/"package.json"

    rm_r libexec/"share" if (libexec/"share").exist?

    # Keg-only: unlike the default node formula, this doesn't touch
    # HOMEBREW_PREFIX/bin — npm/npx live only inside this keg.
    bin.install_symlink libexec/"lib/node_modules/npm/bin/npm-cli.js" => "npm"
    bin.install_symlink libexec/"lib/node_modules/npm/bin/npx-cli.js" => "npx"

    (libexec/"lib/node_modules/npm/npmrc").write("prefix = #{opt_prefix}\n")
  end

  def caveats
    <<~EOS
      This is a keg-only, alternate-toolchain build of node — it is not
      linked into #{HOMEBREW_PREFIX}/bin. Use it explicitly:
        #{opt_bin}/node

      Use this build when you need a nan/node-gyp native addon that's built
      against llvm@21's libc++ ABI (std::__n1::...) to dlopen successfully —
      the default node formula (Alpine GCC / GNU libstdc++) cannot load
      those addons regardless of how they were built.
    EOS
  end

  test do
    # Keg-only, so `bin` isn't on PATH by default. The explicit `#{bin}/...`
    # invocations below don't need this, but npm's own install of itself
    # spawns child processes/scripts with a bare `#!/usr/bin/env node`
    # shebang that does need `node` resolvable via PATH — without this,
    # `npm install npm@latest` fails with "env: 'node': No such file or
    # directory" even though npm itself was invoked by full path.
    ENV.prepend_path "PATH", bin

    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = shell_output("#{bin}/node #{path}").strip
    assert_equal "hello", output
    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"en-EN\").format(1234.56))'").strip
    assert_equal "1,234.56", output

    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"de-DE\").format(1234.56))'").strip
    assert_equal "1.234,56", output

    assert_path_exists bin/"npm", "npm must exist"
    assert_predicate bin/"npm", :executable?, "npm must be executable"
    npm_args = ["-ddd", "--cache=#{HOMEBREW_CACHE}/npm_cache", "--build-from-source"]
    system bin/"npm", *npm_args, "install", "npm@latest"
    system bin/"npm", *npm_args, "install", "nan"
    assert_path_exists bin/"npx", "npx must exist"
    assert_predicate bin/"npx", :executable?, "npx must be executable"
    assert_match "< hello >", shell_output("#{bin}/npx --yes cowsay hello")

    # Test `uvwasi` is linked correctly
    (testpath/"wasi-smoke-test.mjs").write <<~JAVASCRIPT
      import { WASI } from 'node:wasi';

      // Minimal WASM that:
      //   - imports wasi proc_exit(i32)->()
      //   - exports memory (required by Node's WASI binding)
      //   - exports _start which calls proc_exit(42)
      const wasmBytes = new Uint8Array([
        // \0asm + version
        0x00,0x61,0x73,0x6d, 0x01,0x00,0x00,0x00,

        // Type section: 2 types: (i32)->() and ()->()
        0x01,0x08, 0x02,
          0x60,0x01,0x7f,0x00,
          0x60,0x00,0x00,

        // Import section: wasi_snapshot_preview1.proc_exit : func(type 0)
        0x02,0x24, 0x01,
          0x16, // module name len = 22
            0x77,0x61,0x73,0x69,0x5f,0x73,0x6e,0x61,0x70,0x73,0x68,0x6f,0x74,0x5f,0x70,0x72,0x65,0x76,0x69,0x65,0x77,0x31,
          0x09, // name len = 9
            0x70,0x72,0x6f,0x63,0x5f,0x65,0x78,0x69,0x74,
          0x00, // import kind = func
          0x00, // type index 0

        // Function section: 1 function (type index 1 = ()->())
        0x03,0x02, 0x01, 0x01,

        // Memory section: one memory with min=1 page; export later
        0x05,0x03, 0x01, 0x00, 0x01,

        // Export section: export "_start" (func 1) and "memory" (mem 0)
        0x07,0x13, 0x02,
          0x06, 0x5f,0x73,0x74,0x61,0x72,0x74, 0x00, 0x01,
          0x06, 0x6d,0x65,0x6d,0x6f,0x72,0x79, 0x02, 0x00,

        // Code section: body for func 1: i32.const 42; call 0; end
        0x0a,0x08, 0x01,
          0x06, 0x00, 0x41,0x2a, 0x10,0x00, 0x0b
      ]);

      const wasi = new WASI({
        version: 'preview1',
        returnOnExit: true
      });

      const { instance } = await WebAssembly.instantiate(wasmBytes, wasi.getImportObject());

      // This should return 42 if uvwasi is correctly linked & wired.
      const rc = wasi.start(instance);
      if (rc === 42) {
        console.log('PASS: uvwasi proc_exit(42) worked (exitCode=42)');
        process.exit(0);
      } else {
        console.error('FAIL: unexpected return', rc);
        process.exit(2);
      }
    JAVASCRIPT

    system bin/"node", "wasi-smoke-test.mjs"
  end
end
