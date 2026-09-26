class BunAT14 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  url "https://github.com/oven-sh/bun.git",
      tag:      "bun-v1.4.2",
      revision: "744846f844374847c902b5e7fd59b4342a51ef99"
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
  # OHOS patch audit fixes require rebuilding the same upstream version.
  revision 11
  livecheck do
    url :stable
    regex(/^bun[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun@1.4-v1.4.2-r19"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a5fc92745eaa65b8d827aa3282a104e98aa0eb8e48401895c1ddc768996f3b9a"
  end

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "lld@21" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  # Empirically required: without node on PATH the build's first ninja batch
  # dies with exit 127 (command not found) right after the WebKit configure;
  # the bootstrap bun covers the codegen jsRuntime, so some WebKit-phase
  # tooling execs node directly. Do not drop this dep without a full CI run.
  depends_on "node" => :build
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "rustup" => :build
  depends_on "zlib-ng-compat" => :build

  fails_with :gcc do
    cause "uses clang-specific flags"
  end

  # L3 bootstrap: upstream musl Bun used only to run the build scripts.
  # The OHOS userspace provides musl-compatible libc; the GNU C++ runtime is
  # supplied by the gcc dependency below.
  resource "bootstrap" do
    url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-aarch64-musl.zip"
    sha256 "b98e0ad3625c5c00d1d5b5ff55605c7adddbfae151861e68ade57b2d3b8703bb"
  end

  # Apply all exported OHOS patches; the WebKit inner patch is staged here.
  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/bun@1.4/**/*.patch").to_s].each do |path|
    next if path.end_with?(".patch.patch")

    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end
  %w[patches/tinycc/tccgen.c patches/webkit/suspend-resume patches/zstd/ohos-qsort-r].each do |path|
    patch do
      file "Patches/bun@1.4/#{path}.patch.patch"
    end
  end

  def fetch_webkit
    webkit_version = File.read("scripts/build/deps/webkit.ts")[/WEBKIT_VERSION = "(\h+)"/i, 1]
    odie "Unable to find WebKit version!" if webkit_version.blank?

    system "git", "clone", "--branch=autobuild-#{webkit_version}",
           "--config=advice.detachedHead=false", "--config=core.fsmonitor=false",
           "--depth=1", "https://github.com/oven-sh/WebKit.git", "vendor/WebKit"

    cd "vendor/WebKit" do
      # The suspend patch lives in this formula's patch directory
      # (Patches/bun@1.4/); applied here rather than via a DSL patch
      # because vendor/WebKit only exists after the clone above.
      # The inner patch is materialized to the buildpath by the patch
      # loop above (the exporter ships it double-suffixed; the DSL unwraps
      # at staging), so it can be applied to the clone directly.
      suspend_patch = buildpath/"patches/webkit/suspend-resume.patch"
      odie "WebKit suspend patch missing: #{suspend_patch}" unless suspend_patch.file?
      system "git", "apply", "--check", suspend_patch
      system "git", "apply", suspend_patch
      odie "WebKit suspend fix missing" unless File.read("Source/WTF/wtf/Threading.h").include?("m_suspendRequested")
    end
    inreplace "vendor/WebKit/Source/cmake/WebKitFeatures.cmake",
              "find_program(_WEBKIT_PROBE_SWIFTC NAMES swiftc)", ""
  end

  def install
    llvm = Formula["llvm@21"]
    channel = File.read("rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    rust_toolchain = "#{channel}-aarch64-unknown-linux-ohos"
    rustup_home = buildpath/"rustup"
    ENV["RUSTUP_HOME"] = rustup_home
    ENV["CARGO_HOME"] = buildpath/"cargo"
    system "rustup", "toolchain", "install", rust_toolchain, "--profile", "minimal", "--component", "rust-src"
    rust_home = rustup_home/"toolchains"/rust_toolchain
    ENV["BUN_TOOLCHAIN_RUST"] = rust_home
    ENV["RUSTUP_TOOLCHAIN"] = rust_toolchain
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("gcc")/"gcc/current"
    ENV["SSL_CERT_FILE"] = ENV["CURL_CA_BUNDLE"] = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", formula_opt_bin("lld@21")
    # L3 bootstrap bun (from the "bootstrap" resource): runs the build
    # scripts. The resource is an upstream Linux/musl archive.
    (buildpath/"bootstrap").mkpath
    resource("bootstrap").stage do
      (buildpath/"bootstrap").install "bun"
    end
    ENV.prepend_path "PATH", buildpath/"bootstrap"
    ENV["CMAKE_BUILD_PARALLEL_LEVEL"] = ENV.make_jobs.to_s

    # The build resolves ICU via BUN_OHOS_ICU_ROOT. The staging dir carries
    # the keg's headers plus ONLY the static archives, so the link is
    # self-contained: the deployed binary must not depend on the keg's
    # shared libs at runtime (the previous bun formula ships static-ICU
    # binaries for the same reason).
    icu = formula_opt_prefix("icu4c@78")
    icu_stage = buildpath/"build/ohos-icu-static"
    icu_stage.mkpath
    (icu_stage/"include").make_symlink icu/"include"
    (icu_stage/"lib").mkpath
    Dir.glob("#{icu}/lib/*.a").each { |a| (icu_stage/"lib"/File.basename(a)).make_symlink a }
    ENV["BUN_OHOS_ICU_ROOT"] = icu_stage

    fetch_webkit
    ENV["BUN_BUILD_ABI"] = "ohos"
    # The ci-runner container is openharmony userspace: the build detects
    # abi=ohos natively (no cross sysroot involved).
    system "bun", "scripts/build.ts", "--profile=release-local", "--build-dir=build/release-local",
           "--canary=off", "--abi=ohos"

    bin.install "build/release-local/bun"
    bin.install_symlink "bun" => "bunx"
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
