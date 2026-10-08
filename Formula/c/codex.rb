class Codex < Formula
  desc "OpenAI's coding agent that runs in your terminal"
  homepage "https://github.com/openai/codex"
  url "https://github.com/openai/codex/archive/refs/tags/rust-v0.159.1.tar.gz"
  sha256 "dbc5cad4ea2d7cf52996b05c275313e5f84418b3f3afb6a620aa491eadb6e6a1"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^rust[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-v0.159.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18cc128204f0c28d8d3f41a22b6d05bdef662553030f08e4e2e9a5eff9575acd"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"
  depends_on "ripgrep"

  # Keep the v8 version here consistent with the v8 version in Cargo.toml:
  #   https://github.com/openai/codex/blob/main/codex-rs/Cargo.toml
  resource "v8-archive" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.4.0/librusty_v8_release_aarch64-unknown-linux-musl.a.gz"
    sha256 "422555b85082bff3cdd8b05c30e710177191ce6fb1cb66cd036fac53240a1be8"
  end

  # Keep the v8 version here consistent with the v8 version in Cargo.toml:
  #   https://github.com/openai/codex/blob/main/codex-rs/Cargo.toml
  resource "v8-binding" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.4.0/src_binding_release_aarch64-unknown-linux-musl.rs"
    sha256 "7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506"
  end

  # The five patches below only make sense on OpenHarmony; they are applied
  # from the tap's Patches/ directory and are guarded so non-OHOS platforms
  # keep upstream's unpatched source.
  if OS.ohos?
    # ═══════════════════════════════════════════════════════════════════
    # OpenHarmony patches
    #
    #   0001: Default daemon_auto_start back to false. The default home
    #         directory /storage/Users/currentUser is backed by hmdfs, which
    #         does not support unix domain socket files, so the shared
    #         app-server daemon cannot create its control socket under
    #         CODEX_HOME (upstream flipped it to true in 0.157.0).
    #   0002: Select no platform sandbox. The HongMeng kernel syscall-filters
    #         unshare() and landlock_* with SIGSYS kills, so neither the
    #         bubblewrap nor the Landlock sandbox backend can run;
    #         SandboxManager then falls back to SandboxType::None, upstream's
    #         own unsandboxed path for platforms without a backend.
    #   0003: codex-utils-pty (new in 0.158.0) binds
    #         posix_spawn_file_actions_addchdir_np directly on musl and looks
    #         it up with dlsym on glibc; the ohos env matches neither cfg, so
    #         `addchdir` is undefined (E0425). OHOS libc does not export the
    #         symbol at all, so use the dlsym lookup here too: dlsym returns
    #         null and the crate falls back to its compatible spawn helper.
    #   0004: Disable upstream's thin LTO. Codex is a CLI tool, not a
    #         high-performance application; thin LTO adds 60+ minutes to
    #         link time.
    #   0005: Skip close_range(2) in the fork-time descriptor cleanup. The
    #         HongMeng kernel syscall-filters close_range with a SIGSYS kill,
    #         but the cleanup treats any failure as an error and only then
    #         falls back to a /proc/self/fd sweep, so the fallback never runs
    #         and every spawned command dies with exit 159 before executing.
    #         Go straight to the /proc/self/fd sweep on OHOS.
    # ═══════════════════════════════════════════════════════════════════

    patch do
      file "Patches/codex/0001-disable-daemon-auto-start.patch"
    end

    patch do
      file "Patches/codex/0002-disable-sandbox-on-ohos.patch"
    end

    patch do
      file "Patches/codex/0003-pty-addchdir-dlsym-on-ohos.patch"
    end

    patch do
      file "Patches/codex/0004-disable-thin-lto.patch"
    end

    patch do
      file "Patches/codex/0005-skip-close-range-on-ohos.patch"
    end
  end

  def install
    cd "codex-rs" do
      ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
      ENV["OPENSSL_NO_VENDOR"] = "1"
      ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

      if OS.ohos?
        # Clear the cargo cache so the inreplace patches below apply to a
        # freshly fetched copy. Keep the force option: an interrupted build can
        # leave a half-removed tree, and a bare rm_r would abort with
        # Errno::ENOENT on a path that disappears between the glob and removal.
        cache_dir = "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**"
        rm_r(Dir.glob("#{cache_dir}/nix-0.29.0"), force: true)
        rm_r(Dir.glob("#{cache_dir}/rustyline-14.0.0"), force: true)
        rm_r(Dir.glob("#{cache_dir}/v8-*"), force: true)
      end

      system "cargo", "fetch"

      if OS.ohos?
        # The inreplace calls below cannot be patch files under Patches/:
        # nix/rustyline patch dependency crates in the cargo cache (only
        # present after cargo fetch), and the recursion_limit injection
        # covers a set of workspace crate roots that changes every release.
        #
        # Patch nix crate: its cfg condition excludes target_env="musl" but not "ohos",
        # causing cmsg_len() to return usize while the struct field is socklen_t (u32).
        nix_mod = Pathname.glob(
          "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/nix-0.29.0/src/sys/socket/mod.rs",
        ).first
        inreplace nix_mod,
          "not(target_env = \"musl\")",
          "not(any(target_env = \"musl\", target_env = \"ohos\"))"

        # Patch rustyline: ioctl_read_bad! casts TIOCGWINSZ to ioctl_num_type (c_ulong)
        # but libc::ioctl() expects i32. Replace with a direct call.
        rustyline_mod = Pathname.glob(
          "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/rustyline-14.0.0/src/tty/unix.rs",
        ).first
        inreplace rustyline_mod,
          "nix::ioctl_read_bad!(win_size, libc::TIOCGWINSZ, libc::winsize);",
          "unsafe fn win_size(fd: libc::c_int, data: *mut libc::winsize) -> nix::Result<libc::c_int> {
    nix::errno::Errno::result(libc::ioctl(fd, libc::TIOCGWINSZ as i32, data))
}"
      end

      # Deep async nesting + tracing::instrument (exec, cli, app-server, ...)
      # exceeds rustc's default recursion limit (128) on brew's newer rustc
      # (1.98.0 vs upstream's pinned 1.95.0), failing with
      # "error: queries overflow the depth limit!" (query depth 130+).
      # Upstream only sets #![recursion_limit = "256"] in app-server/mcp-server,
      # so raise it on every workspace crate root in one pass; otherwise each
      # newly-compiled crate (exec, cli, code-mode-host, ...) fails in turn.
      Dir.glob(["*/src/lib.rs", "*/src/main.rs", "ext/*/src/lib.rs", "ext/*/src/main.rs"]).each do |crate_root|
        next if File.read(crate_root).include?("recursion_limit")

        inreplace crate_root, /\A/, "#![recursion_limit = \"256\"]\n"
      end

      if OS.ohos?
        ENV["RUSTY_V8_ARCHIVE"] = resource("v8-archive").cached_download
        ENV["RUSTY_V8_SRC_BINDING_PATH"] = resource("v8-binding").cached_download

        # Link clang's builtins library (provides __clear_cache needed by V8)
        builtins = Utils.safe_popen_read("clang", "--print-libgcc-file-name").strip
        ENV.append "RUSTFLAGS", "-L #{File.dirname(builtins)} -C link-arg=-l:libclang_rt.builtins.a"
      end

      # Limit build parallelism to half of available CPU cores to prevent OOM errors
      jobs = [(ENV.make_jobs.to_i / 2), 1].max

      cargo_args = %W[
        --jobs
        #{jobs}
        --locked
        --root=#{prefix}
      ]

      system "cargo", "install", *cargo_args, "--path=cli", "--bin", "codex"
      system "cargo", "install", *cargo_args, "--path=code-mode-host", "--bin", "codex-code-mode-host"
    end
  end

  def caveats
    <<~EOS
      This build disables two upstream features that HarmonyOS cannot support:

      App-server daemon
        The default home directory /storage/Users/currentUser is backed by
        hmdfs, which does not support unix domain socket files, so CODEX_HOME
        cannot host the daemon's control socket.
        Unavailable: `codex agents`, `codex queue`, remote control.

      Command sandboxing
        The HongMeng kernel syscall-filters unshare() and landlock_* with
        SIGSYS kills. Commands run unsandboxed. Approval prompts are the
        only execution guard. Review permissions carefully.
    EOS
  end

  test do
    require "json"

    # Boot-time health check: exercises config loading, auth state probing
    # and environment detection rather than just argument parsing. Pin
    # CODEX_HOME so the auth check deterministically reports no credentials
    # (exit 1) instead of depending on the test host's login state.
    doctor = shell_output("CODEX_HOME=#{testpath} #{bin}/codex doctor", 1)
    assert_match "no Codex credentials were found", doctor

    # The model catalog must render; codex is useless if this regresses.
    models = JSON.parse(shell_output("#{bin}/codex debug models"))
    refute_empty models.fetch("models")

    # Patch 0001 disables the app-server daemon; verify the flag actually
    # evaluates to false at runtime. Only meaningful where that patch applies.
    assert_match(/^daemon_auto_start\s+stable\s+false$/, shell_output("#{bin}/codex features list")) if OS.ohos?

    # Boot the main TUI process in a pty: without credentials it must reach
    # the login prompt. Catches runtime breakage (bad linking, missing
    # resources, panics) that --help never touches. The TUI waits for
    # terminal query responses before rendering, so answer them.
    require "pty"
    require "io/console"
    require "timeout"

    output = +""
    PTY.spawn({ "TERM" => "xterm-256color", "CODEX_HOME" => testpath }, bin/"codex") do |r, w, pid|
      r.winsize = [24, 80]
      begin
        Timeout.timeout(15) do
          loop do
            chunk = r.readpartial(4096)
            output << chunk
            w.write "\e[?0u" if chunk.include?("\e[?u")
            w.write "\e]10;rgb:ffff/ffff/ffff\e\\" if chunk.include?("]10;?")
            w.write "\e]11;rgb:0000/0000/0000\e\\" if chunk.include?("]11;?")
            w.write "\e[?1;2c" if chunk.include?("\e[c")
          end
        end
      rescue Timeout::Error, Errno::EIO, EOFError
        # Expected once the TUI stops or the read side closes; asserted below.
      ensure
        begin
          Process.kill "TERM", pid
          Process.wait pid
        rescue Errno::ESRCH, Errno::ECHILD
          # Already exited between kill and wait.
        end
      end
    end
    assert_match "Sign in with ChatGPT", output

    # No better offline check exists for the code-mode host (its stdio
    # protocol is private and versioned), so a plain boot check stays.
    system bin/"codex-code-mode-host", "--help"
  end
end
