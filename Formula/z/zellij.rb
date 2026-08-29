class Zellij < Formula
  desc "Pluggable terminal workspace"
  homepage "https://zellij.dev"
  # v0.45.0 is the first tag with nix >= 0.30, which is required for the
  # aarch64-unknown-linux-ohos target (older tags pin nix 0.23).
  # Do not add branch: alongside tag:/revision:: Homebrew picks the first
  # ref-type key present, so branch: would silently override the pin.
  url "https://github.com/zellij-org/zellij.git",
      tag: "v0.45.1", revision: "efd8fd5a89a20c07a111d248ad7fce53848d2c18"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "490f2e5a0b4c757832b8327f1f2f4c8a82b3bd2fadaff4a267c74ab22af99a47"
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

  def install
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    # aws-lc-sys only finds its CMake toolchain path on this target; must be
    # the keg root, build.rs appends native/.
    ENV["OHOS_NDK_HOME"] = formula_opt_prefix("ohos-sdk")

    # Cargo.lock pins curl 0.4.44, which pulls socket2 0.4.9 without OHOS
    # support; curl 0.4.50 bumps it to socket2 0.6.x. Lockfile-only change.
    system "cargo", "update", "--package", "curl", "--precise", "0.4.50"

    # close_fds 0.3.2 optimistically calls SYS_close_range (436) on Linux and
    # relies on ENOSYS to fall back; the HarmonyOS sandbox seccomp answers
    # SIGSYS instead, killing the process. Initializing MAY_HAVE_CLOSE_RANGE
    # to false keeps every code path inside the crate's /proc/self/fd +
    # libc::close fallback, so syscall 436 is never issued.
    resource("close_fds").stage do
      inreplace "src/closefds/close.rs",
                "static MAY_HAVE_CLOSE_RANGE: AtomicBool = AtomicBool::new(true);",
                "static MAY_HAVE_CLOSE_RANGE: AtomicBool = AtomicBool::new(false);"
      (buildpath/"vendor/close_fds").install Dir["*"]
    end
    open("Cargo.toml", "a") { |f| f.puts "[patch.crates-io]\nclose_fds = { path = \"vendor/close_fds\" }" }
    system "cargo", "update", "--package", "close_fds", "--precise", "0.3.2"

    # rust libc declares the glibc-only __xpg_strerror_r link_name for the
    # OHOS target; forward it to strerror_r via an object linked through
    # RUSTFLAGS.
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

    # Default features kept: pre-built .wasm plugins ship via include_bytes!.
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"zellij", "setup", "--generate-completion",
                                         base_name: "zellij")
  end

  def caveats
    <<~CAVEATS
      rustls-native-certs may not find a usable system CA store; this only
      affects TLS-verified outbound connections (remote plugins, web server
      HTTPS), not the local terminal multiplexer itself.
    CAVEATS
  end

  test do
    assert_match "keybinds", shell_output("#{bin}/zellij setup --dump-config")
    assert_match "zellij #{version}", shell_output("#{bin}/zellij --version")
  end
end
