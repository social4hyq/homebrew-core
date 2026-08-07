class Herdr < Formula
  desc "Terminal workspace runtime for AI coding agents (built from source)"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "47bdb0753beb8a6b157cf2fec26fbe6b787f85ffea0dde579b0001d6cd663572"
  license "Apache-2.0"
  head "https://github.com/herdrdev/herdr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "ohos-bst-light" => :build # self-sign, see the zig-build note below
  depends_on "rust" => :build
  depends_on "zig@0.15" => :build
  depends_on "ohos-compat-shim"

  def install
    ENV.prepend_path "PATH", formula_opt_bin("zig@0.15")

    # herdr's build.rs invokes `zig build` (see below) to compile the
    # vendored libghostty-vt (Ghostty's VT parser, in vendor/libghostty-vt)
    # into a static lib that cargo then links in. libghostty-vt's
    # build.zig.zon has one non-lazy dependency (uucode, for Unicode table
    # generation) that zig fetches from deps.files.ghostty.org on a cache
    # miss. This tap's local OHOS dev container couldn't reach that specific
    # host at all (2026-08-07: plain TCP connect to its Cloudflare edge IP
    # timed out, while github.com/crates.io/even other Cloudflare-fronted
    # hosts worked fine from the same container — looks like an IP-range
    # block on this one path, not a blanket Cloudflare/CDN restriction, and
    # GitHub-hosted CI runners are on a completely different network so may
    # well not hit this at all). Whether or not CI ever needs it, point the
    # cache at a location that survives across builds (same "prewarm before
    # building" shape as ohos-bun's BUN_INSTALL_CACHE_DIR/
    # BUN_BUILD_PREFETCH_DIR, not a fresh buildpath-relative dir) so this
    # verified-flaky fetch only has to succeed once per machine, not
    # on every single build.
    ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s

    # build.rs's zig_target() maps Rust's TARGET triple onto a zig -Dtarget
    # string via a fixed match table, and panics on anything not in it.
    # aarch64-unknown-linux-ohos (this tap's native rustc host triple — see
    # the "OHOS 容器 cargo/napi 原生 host 编译" note; no cross-compiling
    # involved) isn't in the table. OHOS is aarch64 + musl libc, same as the
    # existing aarch64-unknown-linux-musl entry, so route it onto that same
    # zig target: the resulting static lib is plain object code that gets
    # linked into the final binary by rustc's own (OHOS-aware) linker, not
    # by zig, so zig itself never needs to know "ohos" as a distinct target.
    musl_arm = "\"aarch64-unknown-linux-musl\" => \"aarch64-linux-musl\","
    ohos_arm = "\"aarch64-unknown-linux-ohos\" => \"aarch64-linux-musl\","
    inreplace "build.rs", musl_arm, "#{musl_arm}\n        #{ohos_arm}"

    # OHOS linking fix (same root cause as starship.rb/zellij.rb): rust libc
    # crate declares strerror_r's link_name as __xpg_strerror_r (glibc XPG
    # variant) for OHOS targets, but OHOS musl's dynamic libc doesn't export
    # that symbol. Any std-using binary that formats an io::Error hits this
    # at link time.
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

    # zig's *own* bundled linker — not this tap's patched LLD, which is what
    # normally stamps the OHOS CodeSign section onto everything built via
    # the supervised rustc/cc pipeline (see CLAUDE.md's "签名两层" note) —
    # produces several intermediate ELFs during `zig build` that zig then
    # execs directly, itself: a "build runner", and (for libghostty-vt
    # specifically) a chain of Unicode-table codegen tools
    # (uucode_build_tables -> props-unigen/symbols-unigen -> combine_archives).
    # None of those pass through the supervised toolchain, so none carry a
    # codesign section, and OHOS refuses to exec them (AccessDenied). This
    # is a zig-the-build-tool problem, not a herdr problem — it doesn't
    # touch the final herdr binary at all, which rustc/lld link and sign
    # normally. Verified empirically on real hardware 2026-08-07: `zig
    # build-exe`/`build-obj` (single-artifact compiles) never hit this —
    # only `zig build`'s multi-step orchestration does, because that's what
    # spawns those intermediate tools. A cold `cargo build` (no warm zig
    # cache at all) converges after self-signing ~6 such paths as they turn
    # up, one AccessDenied at a time; self-sign (not binary-sign-tool — see
    # ohos-bst-light.rb) preserves their ELF structure enough to run, and
    # zig's own build cache (keyed by source hash, not output checksum)
    # doesn't mind the external modification on replay.
    self_sign = formula_opt_bin("ohos-bst-light")/"self-sign"
    zig_cache_glob = (buildpath/"vendor/libghostty-vt/.zig-cache/o/*").to_s

    max_attempts = 20
    attempts = 0
    loop do
      attempts += 1
      ohai "cargo install (attempt #{attempts})"
      begin
        Utils.safe_popen_read("cargo", "install", *std_cargo_args, err: :out)
        break
      rescue ErrorDuringExecution => e
        output = e.output&.map(&:last)&.join.to_s
        odie "cargo install did not converge after #{max_attempts} attempts:\n#{output}" if attempts >= max_attempts

        # Only the basename is reliable: the path zig prints is relative to
        # whichever process's cwd emitted it (zig's own vs. cargo's build
        # script sandbox), which varies. Signing every matching basename
        # anywhere under .zig-cache/o/*/ sidesteps that entirely — zig
        # build graphs run in parallel, so more than one tool can come up
        # denied in a single attempt.
        basenames = output.scan(/([A-Za-z0-9_.-]+): AccessDenied/).flatten.uniq
        odie "cargo install failed (no AccessDenied path found):\n#{output}" if basenames.empty?

        signed_any = false
        basenames.each do |basename|
          Dir.glob("#{zig_cache_glob}/#{basename}").each do |candidate|
            next unless File.file?(candidate)

            system self_sign, candidate
            signed_any = true
          end
        end
        odie "cargo install failed: no signable binaries matched #{basenames}:\n#{output}" unless signed_any
      end
    end

    mkdir_p libexec/"bin"
    mv bin/"herdr", libexec/"bin/herdr"
    (bin/"herdr").write <<~SH
      #!/bin/sh
      export TMPDIR="${TMPDIR:-/data/storage/el2/base/tmp}"
      export LD_PRELOAD="#{formula_opt_prefix("ohos-compat-shim")}/lib/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      exec "#{opt_libexec}/bin/herdr" "$@"
    SH
    chmod 0755, bin/"herdr"

    generate_completions_from_executable(libexec/"bin/herdr", "completion")
  end

  def caveats
    <<~EOS
      OHOS has no launchd/systemd, so `brew services` isn't available here.
      Start the server manually:
        herdr server

      Then use `herdr` (the TUI) or any other `herdr` CLI subcommand from
      another terminal. Sessions persist across disconnects; the server
      keeps running until you stop it.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/herdr --version")

    ENV["HOME"] = testpath.to_s
    ENV["TMPDIR"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["HERDR_CONFIG_PATH"] = (testpath/"config.toml").to_s
    ENV["HERDR_SOCKET_PATH"] = (testpath/"herdr.sock").to_s

    pid = spawn bin/"herdr", "server"
    status = ""
    10.times do
      status = shell_output("#{bin}/herdr status server")
      break if status.include?("status: running")

      sleep 1
    end
    assert_match "status: running", status
    assert_match "version: #{version}", status

    output = shell_output("#{bin}/herdr workspace create --label brew-test --no-focus")
    workspace = JSON.parse(output).dig("result", "workspace")
    assert_equal "brew-test", workspace["label"]

    output = shell_output("#{bin}/herdr workspace list")
    workspaces = JSON.parse(output).dig("result", "workspaces")
    assert_includes workspaces.map { |entry| entry["workspace_id"] }, workspace["workspace_id"]
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
