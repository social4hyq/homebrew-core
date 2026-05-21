class NodeAT24 < Formula
  desc "Open-source, cross-platform JavaScript runtime environment"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v24.16.0/node-v24.16.0.tar.xz"
  sha256 "2ff84a6de70b6165290111b0fc656ded1ad207a799816fe720cc7c31232df30f"
  license "MIT"
  compatibility_version 1

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(24(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00768c38e67f775e9a3bbdea58b4e688e3d63cbfa7cc337ce50698de20d11aef"
  end

  keg_only :versioned_formula

  # https://github.com/nodejs/release#release-schedule
  # disable! date: "2028-04-30", because: :unsupported
  deprecate! date: "2027-04-30", because: :unsupported

  resource "alpine-rootfs" do
    url "https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/aarch64/alpine-minirootfs-3.23.4-aarch64.tar.gz"
    sha256 "9250667a8affac8f1e98086392f80f43f086626701e9bce33398eb9b6c0bd64c"
  end

  def install
    # The ohos-sdk compiler (LLVM 15) is outdated and cannot compile Node.js 24.
    # Use Alpine native GCC and statically link libgcc and libstdc++.

    chroot_dir = buildpath/"alpine-chroot"
    chroot_dir.mkpath

    resource("alpine-rootfs").stage do
      system "cp", "-a", ".", chroot_dir.to_s
    end

    if File.exist?("/etc/resolv.conf")
      chroot_dir.join("etc/resolv.conf").write(File.read("/etc/resolv.conf"))
    else
      chroot_dir.join("etc/resolv.conf").write("nameserver 8.8.8.8\n")
    end

    chroot_build_dir = chroot_dir/"build"
    chroot_build_dir.mkpath

    Dir.glob("#{buildpath}/*").each do |file|
      next if file == chroot_dir.to_s
      FileUtils.mv(file, chroot_build_dir)
    end

    chroot_script = <<~SH
      set -e
      export PATH=/bin:/usr/bin:/usr:sbin
      export HOME=/root

      apk update
      apk add build-base python3 linux-headers

      cd /build
      export CC="gcc"
      export CXX="g++"
      ./configure \
        --prefix=#{prefix} \
        --dest-os=openharmony \
        --partly-static

      make -j$(nproc)
      mkdir -p /dest
      make install DESTDIR=/dest
    SH

    chroot_dir.join("build_node.sh").write(chroot_script)
    system "chmod", "+x", "#{chroot_dir}/build_node.sh"

    system "env", "-i", "chroot", chroot_dir.to_s, "/bin/sh", "/build_node.sh"

    chroot_dest_target = chroot_dir/"dest#{prefix}"
    cd chroot_dest_target do
      prefix.install Dir["*"]
    end
  end

  def post_install
    (lib/"node_modules/npm/npmrc").atomic_write("prefix = #{HOMEBREW_PREFIX}\n")
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
