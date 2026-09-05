class NodeOhos < Formula
  desc "Node.js, built with llvm@21 for libc++ ABI compatibility with bun/nan addons"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v26.7.0/node-v26.7.0.tar.xz"
  sha256 "e6b182cbeeab032d1082ca4ac4fe15e3a57de691d3bde78ecf8a761fd56ee356"
  license "MIT"
  revision 2

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/node-ohos-v26.7.0-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb5e919da7dcd7c522a5ef54552b135932d7ee34e7d5ac7a7240c9861abb969d"
  end

  keg_only "alternate toolchain build of node; the harmonybrew/core node formula " \
           "is the default for general use"

  # Toolchain rationale: see the long comment in install().
  depends_on "llvm@21" => :build
  # llvm@21 no longer bundles lld (split into its own formula) — needed here
  # so clang's driver finds the OHOS-codesigned ld.lld, not an unsigned
  # fallback; without a signed ELF, the built node binary can't execute.
  depends_on "lld@21" => :build
  depends_on "ohos-sdk" => :build
  depends_on "python@3.14" => :build

  # Track npm version independently from node releases (--without-npm below).
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
    # harmonybrew/core's node builds with Alpine GCC (GNU libstdc++ ABI), incompatible with
    # llvm@21-built nan/node-gyp addons (libc++ __n1 ABI). Building node itself against llvm@21
    # fixes both: C++20 stdlib pieces the SDK clang lacks, and matching exported symbols.
    llvm = Formula["llvm@21"]
    ENV["CC"]  = (llvm.opt_bin/"clang").to_s
    ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    # gyp's static_library rule shells out to a bare `ar`; superenv's
    # restricted build PATH doesn't provide one (llvm@21 only ships the
    # real name `llvm-ar`, not an `ar` alias).
    ENV["AR"] = (llvm.opt_bin/"llvm-ar").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", llvm.opt_lib
    # clang's driver falls back to PATH to find ld.lld since lld@21 isn't
    # co-located in llvm@21's own bin/ (separate formula now).
    ENV.prepend_path "PATH", formula_opt_bin("lld@21")

    # make sure subprocesses spawned by make are using our Python 3
    ENV["PYTHON"] = which("python3.14")

    # Keep deps/icu-small (ships full ICU data despite the name). --with-intl defaults to
    # full-icu using the bundled copy — no external ICU dependency needed.
    rm_r("deps/npm")

    # Never install the bundled "npm", always prefer our installation from
    # tarball for better packaging control.
    # No --openssl-use-def-ca-store: the compiled-in system CA path isn't populated on OHOS.
    # Omitting it uses Mozilla CA bundle compiled into the binary (no runtime file).
    args = %W[
      --prefix=#{prefix}
      --dest-os=openharmony
      --without-npm
      --shared
      --disable-single-executable-application
    ]

    # Don't devendor node's deps (--shared-uv, etc.): OHOS dlopen() namespace isolation means
    # addons can't resolve symbols from independently-linked .so's without -Wl,-z,global on each.
    # We can add that flag to libnode.so but not to harmonybrew/core's libuv/brotli bottles.
    # harmonybrew/core's own node formulas independently arrived at the same answer (no devendoring).
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

    # OHOS dlopen namespace isolation: addons can't resolve libnode.so symbols unless it's
    # linked with -Wl,-z,global (DF_1_GLOBAL). Threaded through common.gypi (not LDFLAGS)
    # because absolute CC/CXX paths bypass superenv.
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
    # Keg-only: prepend bin to PATH for npm's bare `#!/usr/bin/env node` shebang.
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
