class Zellij < Formula
  desc "Pluggable terminal workspace, with terminal multiplexer as the base feature"
  homepage "https://zellij.dev"
  url "https://github.com/zellij-org/zellij/archive/refs/tags/v0.45.1.tar.gz"
  sha256 "5cbe711437d2a61afd9287165f6aca0bcccb9ab1473633665a5b11ed55467852"
  license "MIT"
  head "https://github.com/zellij-org/zellij.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zellij-v0.45.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa28295e9abafb7b34ebf671691e2356848db0bc65f9664a71442749c7c7dffd"
  end

  depends_on "cmake" => :build
  depends_on "make" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"
  depends_on "zlib-ng-compat"

  resource "close_fds" do
    url "https://static.crates.io/crates/close_fds/close_fds-0.3.2.crate"
    sha256 "3bc416f33de9d59e79e57560f450d21ff8393adcf1cdfc3e6d8fb93d5f88a2ed"
  end

  service do
    run [opt_bin/"zellij", "web"]
    keep_alive true
    environment_variables PATH: std_service_path_env
    log_path var/"log/zellij.log"
    error_log_path var/"log/zellij.log"
  end

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    # OHOS_NDK_HOME must point to ohos-sdk keg root (not native/): aws-lc-sys's
    # build.rs double-appends "native/" to find ohos.toolchain.cmake. aws-lc-sys
    # only has OHOS support via CMake path; NO_ASM panics under --release.
    ENV["OHOS_NDK_HOME"] = formula_opt_prefix("ohos-sdk")

    # Cargo.lock's curl 0.4.44 → socket2 0.4.9 lacks OHOS support; bump curl to 0.4.50
    # (loose isahc requirement allows it) pulls socket2 0.6.5. `--locked` stays consistent.
    system "cargo", "update", "--package", "curl", "--precise", "0.4.50"

    # close_fds 0.3.2 optimistically calls SYS_CLOSE_RANGE (436) on Linux and
    # expects ENOSYS to fall back; the HarmonyOS sandbox seccomp answers SIGSYS
    # instead, killing the process (intermittent startup crash in a fresh PTY).
    # Flipping MAY_HAVE_CLOSE_RANGE to false keeps every code path inside the
    # crate's /proc/self/fd + libc::close fallback, so no shim is needed.
    resource("close_fds").stage do
      inreplace "src/closefds/close.rs",
                "static MAY_HAVE_CLOSE_RANGE: AtomicBool = AtomicBool::new(true);",
                "static MAY_HAVE_CLOSE_RANGE: AtomicBool = AtomicBool::new(false);"
      (buildpath/"vendor/close_fds").install Dir["*"]
    end
    open("Cargo.toml", "a") { |f| f.puts "[patch.crates-io]\nclose_fds = { path = \"vendor/close_fds\" }" }
    # Re-resolve just this package so --locked accepts the patched source.
    system "cargo", "update", "--package", "close_fds", "--precise", "0.3.2"

    # OHOS strerror_r link fix — same approach as starship.rb.
    (buildpath/"strerror_shim.rs").write <<~RUST
      #[no_mangle]
      pub extern "C" fn __xpg_strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32 {
          extern "C" { fn strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32; }
          unsafe { strerror_r(errnum, buf, buflen) }
      }
    RUST
    system "rustc", "--edition", "2021", "--crate-type", "staticlib", "--emit", "obj",
           "-O", "strerror_shim.rs", "-o", "strerror_shim.o"
    ENV["RUSTFLAGS"] = "-C link-arg=#{buildpath}/strerror_shim.o"

    # Default features kept: pre-built .wasm plugins ship via include_bytes!;
    # vendored_curl/web_server_capability bundle their own C sources.
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"zellij", "setup", "--generate-completion")
  end

  def caveats
    <<~CAVEATS
      rustls-native-certs may not find a usable OHOS system CA store;
      only affects TLS-verified outbound (remote plugins, web server HTTPS) —
      not the local terminal multiplexer itself.
    CAVEATS
  end

  test do
    assert_match "keybinds", shell_output("#{bin}/zellij setup --dump-config")
    assert_match "zellij #{version}", shell_output("#{bin}/zellij --version")
  end
end
