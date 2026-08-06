class Zellij < Formula
  desc "Pluggable terminal workspace — HarmonyOS aarch64, built from source"
  homepage "https://zellij.dev"
  # v0.44.3 (latest tag) pins `nix = "0.23.1"` in its workspace Cargo.toml.
  # nix only gained *-unknown-linux-ohos support in 0.30 (nix-rust/nix#2599/
  # #2587/#2456) — under 0.23 the OHOS target is misclassified as glibc and
  # zellij-server's os_input_output_unix.rs (openpty/fcntl/termios) fails to
  # compile (u32/i32 type mismatches). Reimplementing that upgrade ourselves
  # would mean redoing work upstream has already done: `main` bumped
  # nix to 0.30 and daemonize -> daemonix (which also gained OHOS support)
  # ahead of the next tag. So this formula tracks a pinned `main` revision
  # instead of the v0.44.3 tag (same shape as `opencode@2.rb`'s v2-branch
  # pin) until v0.45.0 ships, at which point this should switch back to a
  # normal tagged url + version and drop this comment block.
  url "https://github.com/zellij-org/zellij.git",
      revision: "5254e4fc1dd784ef872644190dc5e2bcb0981bed", branch: "main"
  version "0.45.0-dev"
  license "MIT"

  livecheck do
    url "https://api.github.com/repos/zellij-org/zellij/commits?sha=main&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zellij-v0.45.0-dev-r2"
    rebuild 1
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "1575b2c17a18e7d8560adcc262cdeba6cb54486df71ea68f2a2de4526a3de375"
  end

  depends_on "cmake" => :build
  depends_on "make" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "ohos-compat-shim"
  depends_on "openssl@3"
  depends_on "zlib-ng-compat"

  def install
    # Ensure the `openssl` crate picks up the brew-built library instead of
    # trying to vendor/compile its own OpenSSL from C source.
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    # web_server_capability pulls in axum-server -> rustls -> aws-lc-rs
    # (aws-lc-sys), whose build.rs only has pregenerated assembly for a
    # fixed triple allowlist (gnu/musl variants) — aarch64-unknown-linux-ohos
    # isn't in it, so the plain cc build leaves bcm.c referencing hand-tuned
    # asm symbols (aws_lc_*_AES_*, bn_*) that were never compiled, and the
    # final link fails with "undefined symbol". aws-lc-sys does have real
    # OHOS support, but only through its CMake builder path, which shells
    # out to a bundled `ohos.toolchain.cmake` under $OHOS_NDK_HOME/native —
    # confirmed against ohos-sdk's actual keg layout (`opt/ohos-sdk` is the
    # root; the toolchain file is under `native/build/cmake/`, so
    # OHOS_NDK_HOME must be the *keg root*, not the `native/` dir itself, or
    # aws-lc-sys's build.rs double-appends "native/" and can't find it).
    # NO_ASM (the simpler-looking escape hatch) is a dead end: it panics
    # with "only allowed for debug builds" under --release, so this is not
    # optional — the CMake path via ohos-sdk is the only way to get a
    # release build of aws-lc-sys on this target.
    ENV["OHOS_NDK_HOME"] = formula_opt_prefix("ohos-sdk")

    # zellij's Cargo.lock (via isahc -> curl 0.4.44) locks socket2 0.4.9,
    # which predates OpenHarmony support (added in socket2 0.5.6, PR
    # rust-lang/socket2#491) — msg.msg_iovlen's platform-conditional
    # `IovLen` type has no arm for target_env=ohos, so it fails to compile.
    # curl-rust 0.4.50 bumped its own socket2 requirement to "0.6", so a
    # plain `cargo update` (still satisfying isahc 1.7.2's loose `curl`
    # requirement, no Cargo.toml edits) picks up socket2 0.6.5 and resolves
    # it. `--locked` below is safe: this only rewrites Cargo.lock, it stays
    # internally consistent with what Cargo.toml allows.
    system "cargo", "update", "--package", "curl", "--precise", "0.4.50"

    # OHOS linking fix (same root cause as starship.rb): rust libc crate
    # declares strerror_r's link_name as __xpg_strerror_r (glibc XPG
    # variant) for OHOS targets, but OHOS musl's dynamic libc does not
    # export that symbol (only a weak alias in the static libc.a). Any
    # std-using Rust binary that formats an io::Error hits this at link
    # time. Provide a forwarding shim object and inject it via RUSTFLAGS.
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

    # Default features (plugins_from_target, vendored_curl, web_server_capability)
    # are kept: the 13 default-plugin .wasm files ship pre-built in
    # zellij-utils/assets/plugins/ and are pulled in via include_bytes! in
    # release builds regardless of plugins_from_target (that feature only
    # matters for `cargo run` in debug builds against a local target/ dir);
    # vendored_curl/web_server_capability bundle their own C sources
    # (curl-sys, openssl-sys already covered above, rusqlite) so no extra
    # system deps are needed beyond openssl@3/zlib-ng-compat.
    system "cargo", "install", *std_cargo_args

    # OHOS app sandbox: interactive shells here do get TMPDIR pointed at a
    # writable EL2 path already, but zellij's own temp/socket dir resolution
    # (ZELLIJ_TMP_DIR = env::temp_dir()/zellij-<uid>) falls back to /tmp in
    # any context TMPDIR is missing — confirmed: `env -u TMPDIR zellij setup
    # --check` panics on log file creation with ReadOnlyFilesystem (OHOS
    # /tmp is read-only). The wrapper defends that edge, mirroring
    # opencode@2.rb's pattern.
    #
    # LD_PRELOAD ohos-compat-shim is load-bearing, not defensive: without it,
    # zellij intermittently fails to start with "Bye from Zellij!" printed
    # within ~100ms (ExitReason::Normal) in a genuinely fresh top-level PTY
    # (a brand new hishell terminal window/tab; not reproducible when nested
    # under an already-running pty-owning process like tmux). Root-caused via
    # zellij's --debug log: PtyInstruction spawns the first pane's PTY, then
    # `terminal_bytes.rs: I/O error (os error 5)` (EIO — the standard "slave
    # side's controlling process died" signal) immediately follows, cascading
    # into `Failed to get CWD for pane Terminal(0)` and several plugin-thread
    # panics before the session exits cleanly. zellij's PTY spawn
    # (os_input_output_unix.rs) does `login_tty()` then
    # `close_fds::close_open_fds(3, &[])` in a forked child's `pre_exec`; on
    # Linux that crate's fast path is a raw `libc::syscall(SYS_CLOSE_RANGE,
    # ...)` (436) with no availability probe (unlike its FreeBSD path, which
    # explicitly guards against exactly this because an unrecognized syscall
    # can get a process SIGSYS-killed by some kernels/sandboxes instead of
    # cleanly returning ENOSYS).
    #
    # Confirmed empirically, not guessed: `libohos_compat.so` exports
    # `close_range`, `syscall`, and `getcwd` — i.e. it's already
    # LD_PRELOAD-interposing exactly the calls in this failure chain (the
    # `getcwd` intercept is the same fix behind the historical OHOS
    # EL2-sandbox chdir+exec getcwd bug documented for ohos-bun's
    # Bun.spawn({cwd})). A same-machine A/B test replaying zellij's exact
    # fork+login_tty+close_fds pattern (openpty, fork, login_tty, exec the
    # real `zellij` binary, 20 iterations) went 20/20 clean with the shim
    # preloaded and 12/20 clean (8 crashes, same "Bye from Zellij!"/EIO
    # signature) with `LD_PRELOAD` unset — i.e. running exactly what a
    # fresh, un-shimmed hishell shell gives you.
    mkdir_p libexec/"bin"
    mv bin/"zellij", libexec/"bin/zellij"
    (bin/"zellij").write <<~SH
      #!/bin/sh
      export TMPDIR="${TMPDIR:-/data/storage/el2/base/tmp}"
      export LD_PRELOAD="#{formula_opt_prefix("ohos-compat-shim")}/lib/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      exec "#{opt_libexec}/bin/zellij" "$@"
    SH
    chmod 0755, bin/"zellij"

    generate_completions_from_executable(libexec/"bin/zellij", "setup", "--generate-completion",
                                         base_name: "zellij")
  end

  def caveats
    <<~CAVEATS
      rustls-native-certs may not find a usable OHOS system CA store, which
      only affects remote plugin URLs / the web server's TLS trust chain —
      not the local terminal multiplexer itself (`zellij web --start` binds
      and serves plain HTTP fine without a CA store; only TLS-verified
      outbound connections would be affected).
    CAVEATS
  end

  test do
    assert_match "keybinds", shell_output("#{bin}/zellij setup --dump-config")
    assert_match "zellij 0.45.0", shell_output("#{bin}/zellij --version")
  end
end
