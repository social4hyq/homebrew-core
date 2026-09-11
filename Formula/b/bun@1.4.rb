class BunAT14 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  url "https://github.com/oven-sh/bun.git",
      revision: "744846f844374847c902b5e7fd59b4342a51ef99" # bun-v1.4.2
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
  revision 1

  livecheck do
    url :stable
    regex(/^bun-v?(1\.4(?:\.\d+)*)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun@1.4-v1.4.2-r5"
    rebuild 3
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2130354d9095aa8b284298e7daab2867c9ac3020b9076d231265f5c3e829f9da"
  end

  keg_only :versioned_formula

  depends_on "bun-bootstrap" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "lld@21" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "node" => :build
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "zlib-ng-compat" => :build

  fails_with :gcc do
    cause "uses clang-specific flags"
  end

  # Per-file patches for OHOS portability, exported from the ohos-aarch64
  # branch of social4hyq/ohos-bun (scripts/export-ohos-patches.sh; its
  # replay check proves the series reproduces the branch tip bit-for-bit).
  # Split per file so upstream version bumps only reject the affected
  # file(s) instead of a multi-file mega-patch.
  %w[
    Cargo.lock
    Cargo.toml
    bun.lock
    package.json
    packages/bun-usockets/src/eventing/epoll_kqueue.c
    patches/zstd/ohos-qsort-r.patch
    scripts/build.ts
    scripts/build/bun.ts
    scripts/build/codegen.ts
    scripts/build/config.ts
    scripts/build/deps/cares.ts
    scripts/build/deps/mimalloc.ts
    scripts/build/deps/webkit.ts
    scripts/build/deps/zstd.ts
    scripts/build/fetch-cli.ts
    scripts/build/flags.ts
    scripts/build/rust.ts
    scripts/build/shims.ts
    scripts/build/shims/ohos_compat_shim.c
    scripts/build/source.ts
    scripts/build/stream.ts
    scripts/build/tools.ts
    scripts/build/workarounds.ts
    src/bun_core/Global.rs
    src/bun_core/env.rs
    src/bun_core/env_var.rs
    src/bun_core/feature_flags.rs
    src/bun_core/util.rs
    src/crash_handler/lib.rs
    src/dns/lib.rs
    src/event_loop/SpawnSyncEventLoop.rs
    src/exe_format/elf.rs
    src/install/Cargo.toml
    src/install/PackageInstall.rs
    src/install/PackageInstaller.rs
    src/install/PackageManager.rs
    src/install/PackageManager/CommandLineArguments.rs
    src/install/PackageManager/PackageManagerLifecycle.rs
    src/install/isolated_install/Installer.rs
    src/install/lib.rs
    src/install/lockfile/bun.lockb.rs
    src/install/npm.rs
    src/install_jsc/npm_jsc.rs
    src/install_types/resolver_hooks.rs
    src/io/ParentDeathWatchdog.rs
    src/io/PipeReader.rs
    src/io/PipeWriter.rs
    src/io/lib.rs
    src/io/pipes.rs
    src/io/posix_event_loop.rs
    src/js/node/os.ts
    src/js/wasi-runner.js
    src/jsc/bindings/BunProcess.cpp
    src/jsc/bindings/bun-spawn.cpp
    src/jsc/bindings/c-bindings.cpp
    src/jsc/bindings/wtf-bindings.cpp
    src/libarchive/lib.rs
    src/linker.lds
    src/node-fallbacks/bun.lock
    src/node-fallbacks/package.json
    src/ohos_sign/Cargo.lock
    src/ohos_sign/Cargo.toml
    src/ohos_sign/src/bin/ohos_selfsign.rs
    src/ohos_sign/src/descriptor.rs
    src/ohos_sign/src/elf.rs
    src/ohos_sign/src/lib.rs
    src/ohos_sign/src/merkle.rs
    src/ohos_sign/src/sha256.rs
    src/options_types/compile_target.rs
    src/resolver/lib.rs
    src/resolver/resolver.rs
    src/runtime/Cargo.toml
    src/runtime/api.rs
    src/runtime/api/bun/Terminal.rs
    src/runtime/api/bun/js_bun_spawn_bindings.rs
    src/runtime/api/bun/ohos_node_userinfo.rs
    src/runtime/api/bun/spawn/stdio.rs
    src/runtime/api/bun/subprocess.rs
    src/runtime/api/js_bundle_completion_task.rs
    src/runtime/cli/Arguments.rs
    src/runtime/cli/build_command.rs
    src/runtime/cli/create/SourceFileProjectGenerator.rs
    src/runtime/cli/filter_run.rs
    src/runtime/cli/init/react-shadcn/package.json
    src/runtime/cli/init/react-tailwind/package.json
    src/runtime/cli/run_command.rs
    src/runtime/cli/test/parallel/Coordinator.rs
    src/runtime/cli/upgrade_command.rs
    src/runtime/dns_jsc/dns.rs
    src/runtime/error.rs
    src/runtime/ffi/ffi_body.rs
    src/runtime/napi/napi_body.rs
    src/runtime/node/node_fs.rs
    src/runtime/node/node_net_binding.rs
    src/runtime/node/node_process.rs
    src/runtime/node/path_watcher.rs
    src/runtime/shell/builtin/echo.rs
    src/runtime/shell/builtin/which.rs
    src/runtime/shell/subproc.rs
    src/runtime/socket/Listener.rs
    src/runtime/socket/socket_body.rs
    src/runtime/socket/system_certs.rs
    src/runtime/webcore/blob/read_file.rs
    src/spawn/process.rs
    src/spawn_sys/spawn_process.rs
    src/standalone_graph/StandaloneModuleGraph.rs
    src/sys/Cargo.toml
    src/sys/lib.rs
    src/sys/linux_syscall.rs
  ].each do |p|
    patch do
      file "Patches/bun@1.4/#{p}.patch"
    end
  end
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-07-20/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    version "nightly-2026-07-20"
    sha256 "7d3dd4cc4f55ee8a7c7f09804b96fd52ef7ef598a935772091e80aa66869676e"
  end

  resource "rust-src" do
    url "https://static.rust-lang.org/dist/2026-07-20/rust-src-nightly.tar.gz"
    version "nightly-2026-07-20"
    sha256 "2be85b655b99624bed0fb63a47e564abac07aa1fb5d0576abac5c42ef8c5316e"
  end

  resource "webkit-suspend-fix" do
    url "https://raw.githubusercontent.com/social4hyq/homebrew-core/ad1c1f23f/Patches/bun-webkit/0001-suspend-resume-handshake-survives-signal-loss.patch"
    sha256 "8a8dc62036979949277c83df3070d40b57a6a703ab872f6d1a96799e9e384f4a"
  end

  def fetch_webkit
    webkit_version = File.read("scripts/build/deps/webkit.ts")[/WEBKIT_VERSION = "(\h+)"/i, 1]
    odie "Unable to find WebKit version!" if webkit_version.blank?

    system "git", "clone", "--branch=autobuild-#{webkit_version}",
           "--config=advice.detachedHead=false", "--config=core.fsmonitor=false",
           "--depth=1", "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"

    cd "vendor/WebKit" do
      system "git", "apply", "--check", resource("webkit-suspend-fix").cached_download
      system "git", "apply", resource("webkit-suspend-fix").cached_download
      odie "WebKit suspend fix missing" unless File.read("Source/WTF/wtf/Threading.h").include?("m_suspendRequested")
    end
    inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
              "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""
  end

  def install
    llvm = Formula["llvm@21"]
    sdk = llvm.deps.find { |dep| dep.name.start_with?("ohos-sdk@") }.to_formula.opt_prefix
    rust_home = buildpath/"rust"
    channel = File.read("rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    odie "Update rust-nightly to #{channel}" if resource("rust-nightly").version.to_s != channel

    %w[rust-nightly rust-src].each do |name|
      resource(name).stage do
        system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
      end
    end
    ENV["BUN_TOOLCHAIN_RUST"] = rust_home
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    ENV["SSL_CERT_FILE"] = ENV["CURL_CA_BUNDLE"] = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", formula_opt_bin("lld@21")
    ENV.prepend_path "PATH", formula_opt_bin("bun-bootstrap")

    # The fork still expects separate libc++/libc++abi/libunwind directories.
    cross_libs = buildpath/"build/ohos-cross-libs"
    %w[libcxx libcxxabi libunwind].each do |name|
      (cross_libs/name).mkpath
      (cross_libs/name/"lib").make_symlink llvm.opt_lib/"aarch64-linux-ohos"
    end
    (cross_libs/"libcxx/include").mkpath
    (cross_libs/"libcxx/include/v1").make_symlink llvm.opt_include/"c++/v1"
    (cross_libs/"libcxxabi/include").make_symlink llvm.opt_include/"c++/v1"
    (buildpath/"build/ohos-icu").mkpath
    (buildpath/"build/ohos-icu/target").make_symlink formula_opt_prefix("icu4c@78")

    fetch_webkit
    system "bun", "run", "build:release:local", "--canary=off",
           "--os=ohos", "--arch=aarch64",
           "--ohos-sdk-root=#{sdk}", "--ohos-sysroot=#{sdk}/native/sysroot"

    bin.install "build/release-local/bun"
    (bin/"bunx").make_symlink "bun"
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
