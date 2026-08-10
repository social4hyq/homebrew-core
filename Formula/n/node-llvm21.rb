class NodeLlvm21 < Formula
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

  depends_on "llvm@21" => :build
  depends_on "ohos-sdk" => :build
  depends_on "python@3.14" => :build
  depends_on "openssl@3"

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
    # Verified on-device: full build compiles clean, passes this formula's
    # own smoke tests (console.log, ICU/Intl, WASI), and a nan-style addon
    # (@datadog/pprof) that fails to dlopen under the standard node formula
    # dlopens and runs correctly against this build.
    llvm = Formula["llvm@21"]
    ENV["CC"]  = (llvm.opt_bin/"clang").to_s
    ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    # gyp's static_library rule shells out to a bare `ar`, which superenv's
    # restricted build PATH doesn't provide (only declared deps' opt/bin —
    # llvm@21 only ships the real name `llvm-ar`, not an `ar` alias).
    ENV["AR"] = (llvm.opt_bin/"llvm-ar").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", llvm.opt_lib

    system "./configure",
           "--prefix=#{prefix}",
           "--dest-os=openharmony",
           "--partly-static"

    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"

    # Node's bundled OpenSSL 3.x tries to auto-load a config file at every
    # process startup (provider initialization), and hard-fails if it's
    # missing rather than tolerating its absence — confirmed fatal in an
    # OpenHarmony docker container (fine on real hardware, so this wasn't
    # caught until tested there). The compiled-in default is /etc/ssl,
    # which this platform doesn't populate. Point at this tap's own
    # openssl@3 config (which does exist) via a wrapper instead of relying
    # on system state — same pattern warp-tui.rb already uses for its own
    # OpenSSL dependency.
    libexec.mkpath
    mv bin/"node", libexec/"node-real"
    (bin/"node").write <<~SH
      #!/bin/sh
      export OPENSSL_CONF="#{formula_opt_prefix("openssl@3")}/etc/openssl@3/openssl.cnf"
      exec "#{libexec}/node-real" "$@"
    SH
    chmod 0755, bin/"node"
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

      #{bin}/node is a wrapper that points OPENSSL_CONF at this tap's own
      openssl@3 config (the compiled-in default, /etc/ssl, isn't populated
      on this platform) — invoke it directly rather than #{libexec}/node-real.
    EOS
  end

  test do
    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = shell_output("#{bin}/node #{path}").strip
    assert_equal "hello", output
    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"en-EN\").format(1234.56))'").strip
    assert_equal "1,234.56", output

    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"de-DE\").format(1234.56))'").strip
    assert_equal "1.234,56", output

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
