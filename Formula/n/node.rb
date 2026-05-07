class Node < Formula
  desc "Open-source, cross-platform JavaScript runtime environment"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v26.1.0/node-v26.1.0.tar.xz"
  sha256 "779a1364889575d44e0215adc381806bbd0d9437557b59893e172f5b9d35a990"
  license "MIT"
  head "https://github.com/nodejs/node.git", branch: "main"

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "75589bcf1224b8bbc606d3bbeeeff21d352a6a85a07f468b787a4e84ec632004"
  end

  # Disable superenv
  env :std
  
  depends_on "python@3.14" => :build

  # Use a mirror site for downloading Zig due to the instability of official links.
  resource "zig" do
    url "https://pkg.earth/zig/zig-aarch64-linux-0.15.2.tar.xz"
    sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  end

  def install
    # Setup the Zig compiler.
    resource("zig").stage do
      (buildpath/"zig-toolchain").install Dir["*"]
    end
    zig_bin = buildpath/"zig-toolchain/zig"

    # Environment reset.
    # The ohos-sdk compiler (LLVM 15) is outdated and cannot compile newer Node.js versions.
    # Using Zig (built-in LLVM 20) as the compiler with static linking to its internal musl libc.
    jobs = ENV.make_jobs
    ENV.clear
    ENV["HOME"] = "/root"
    ENV["PATH"] = "#{buildpath}/zig-toolchain:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin"
    ENV["CC"] = "#{zig_bin} cc -target aarch64-linux-musl"
    ENV["CXX"] = "#{zig_bin} c++ -target aarch64-linux-musl"
    ENV["AR"] = "#{zig_bin} ar"
    ENV["GYP_DEFINES"] = "OS=openharmony"

    # Disable Thin Archive support, as it is currently incompatible with the Zig linker.
    inreplace "tools/gyp/pylib/gyp/generator/make.py", "crsT", "crs"

    system "./configure", "--prefix=#{prefix}"
    system "make", "-j#{jobs}"
    system "make", "install"

    system "llvm-strip", bin/"node"
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

    # make sure npm can find node
    ENV.prepend_path "PATH", opt_bin
    ENV.delete "NVM_NODEJS_ORG_MIRROR"
    assert_equal which("node"), opt_bin/"node"
    assert_path_exists HOMEBREW_PREFIX/"bin/npm", "npm must exist"
    assert_predicate HOMEBREW_PREFIX/"bin/npm", :executable?, "npm must be executable"
    npm_args = ["-ddd", "--cache=#{HOMEBREW_CACHE}/npm_cache", "--build-from-source"]
    system HOMEBREW_PREFIX/"bin/npm", *npm_args, "install", "npm@latest"
    system HOMEBREW_PREFIX/"bin/npm", *npm_args, "install", "nan"
    assert_path_exists HOMEBREW_PREFIX/"bin/npx", "npx must exist"
    assert_predicate HOMEBREW_PREFIX/"bin/npx", :executable?, "npx must be executable"
    assert_match "< hello >", shell_output("#{HOMEBREW_PREFIX}/bin/npx --yes cowsay hello")

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
