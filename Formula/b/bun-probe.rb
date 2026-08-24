class BunProbe < Formula
  desc "DIAGNOSTIC ONLY bun build with WaiterThread wait4() tracing"
  homepage "https://github.com/oven-sh/bun"
  url "https://github.com/social4hyq/ohos-bun.git", revision: "4e6a6836e23a0e3cc33d87a22d6ac1a84ec1c24e", branch: "debug/waiter-thread-terminal-race"
  version "1.4.0-probe1"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-probe-v1.4.0-probe1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b3c7128c8a4a55ee2cc3d998abb34a0552e3d3d57a194199293f190bf4f8454d"
  end

  keg_only "diagnostic-only build, never the default `bun`"

  depends_on "bun-bootstrap" => :build
  depends_on "bun-webkit" => :build
  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "icu4c@78" => :build
  depends_on "llvm@21" => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  depends_on "openssl@3" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "node"

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

  def install
    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    cache_dir = HOMEBREW_CACHE/"bun-build-cache"

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
    icu = Formula["icu4c@78"]
    %w[libicudata.a libicui18n.a libicuuc.a].each do |a|
      ln_sf icu.opt_lib/a, wc/"lib"/a
    end

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

    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    system "bun", "install"
    system "bun", "install", "--cwd", "src/node-fallbacks"

    rust_ver = resource("rust-nightly").version.to_s
    rust_home = Pathname.new("/data/storage/el2/base/tmp/rust-#{rust_ver}")
    rust_ready = rust_home/"BREW_SIGNED_OK"

    rust_home.mkpath
    File.open(rust_home/".brew-install-lock", File::CREAT | File::RDWR) do |lock|
      lock.flock(File::LOCK_EX)
      unless rust_ready.exist?
        resource("rust-nightly").stage do
          system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
        end
        resource("rust-src").stage do
          system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
        end

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

    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("libxml2").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("openssl@3").to_s
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    ohos_cross = buildpath/"build/ohos-cross-libs"
    (ohos_cross/"libcxx/include").mkpath
    (ohos_cross/"libcxxabi").mkpath
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxx/include/v1"
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxxabi/include"
    {
      "libcxx"    => "libc++.a",
      "libcxxabi" => "libc++abi.a",
      "libunwind" => "libunwind.a",
    }.each do |d, a|
      (ohos_cross/d/"lib").mkpath
      ln_sf llvm.opt_lib/"aarch64-linux-ohos"/a, ohos_cross/d/"lib"/a
    end
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
    ENV["TMPDIR"] = "/data/storage/el2/base/tmp"

    sysroot = formula_opt_prefix("ohos-sdk")/"native/sysroot"
    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=off",
           "--cache-dir=#{cache_dir}",
           "--ohos-sdk-root=#{formula_opt_prefix("ohos-sdk")}",
           "--ohos-sysroot=#{sysroot}"

    out = buildpath/"build/release/bun"
    odie "bun binary missing after build: #{out}" unless out.exist?
    sign_tool = formula_opt_bin("ohos-sdk")/"binary-sign-tool"
    unsigned = "#{out}.unsigned"
    mv out, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", out
    chmod 0755, out
    rm unsigned
    mkdir_p libexec/"bin"
    libexec.install out => "bin/bun"
    bin.mkpath
    (bin/"bun").make_symlink "../libexec/bin/bun"
  end

  def caveats
    <<~EOS
      DIAGNOSTIC-ONLY build (keg-only, not linked). Investigating a
      Bun.spawn({terminal}) premature-exit race:
        BUN_DEBUG_WAITER_THREAD=1 #{opt_bin}/bun ...
    EOS
  end

  test do
    assert_match version.to_s.split("-").first, shell_output("#{bin}/bun --version")
  end
end
