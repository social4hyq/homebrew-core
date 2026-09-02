class Herdr < Formula
  desc "Terminal workspace runtime for AI coding agents (built from source)"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr/archive/refs/tags/v0.8.2.tar.gz"
  sha256 "60453051025ee44ebf055d26cdaf665a0accd99a992cddd22c166a26c49cd161"
  license "Apache-2.0"
  revision 1
  head "https://github.com/herdrdev/herdr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-v0.8.2-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8eda9844b198a95c712b7f71b2345f68acbce796e083d919f1eec3f1af85edba"
  end

  depends_on "rust" => :build

  # libghostty-vt pins minimum_zig_version 0.15.2; build with the official
  # prebuilt static aarch64-linux zig instead of the zig@0.15 keg.
  resource "zig" do
    url "https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz"
    sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  end

  # build.rs's Rust-TARGET→zig-target table doesn't know OHOS; route onto musl.
  patch :p1 do
    file "Patches/herdr/build-rs-zig-target-ohos.patch"
  end

  # OHOS procfs gives no tty foreground process group and no task children, so
  # agent detection falls back to tcgetpgrp() on the pane's own PTY master fd.
  patch :p1 do
    file "Patches/herdr/pane-agent-detection-tcgetpgrp.patch"
  end

  def install
    # toybox patch can print "Hunk N FAILED" yet exit 0 and apply nothing
    # (observed with plain context drift) — never trust its exit code; verify
    # one marker per patched file instead (application is atomic per file).
    {
      "build.rs"    => '"aarch64-unknown-linux-ohos" => "aarch64-linux-musl"',
      "src/pane.rs" => "pty_actor_foreground_process_group(&pty_actor)",
    }.each do |file, marker|
      odie "herdr: #{file} OHOS patch not applied" unless File.read(file).include?(marker)
    end

    # Stage and sign the zig toolchain (official static build; binary-sign-tool
    # is proven safe on it). zig resolves lib/ via self-exe-realpath, so keep
    # the unpacked tree intact and put its dir on PATH for build.rs.
    resource("zig").stage(buildpath/"zig-toolchain")
    zig = buildpath/"zig-toolchain/zig"
    system "binary-sign-tool", "sign", "-selfSign", "1",
           "-inFile", zig.to_s, "-outFile", "#{zig}.signed"
    mv "#{zig}.signed", zig
    chmod 0755, zig
    ENV.prepend_path "PATH", zig.dirname.to_s

    # libghostty-vt's build.zig.zon has a non-lazy dep (uucode) fetched from deps.files.ghostty.org,
    # which is unreachable from this container. Persistent cache ensures the fetch only
    # needs to succeed once per machine.
    ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s

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

    # zig's own linker (not this tap's patched LLD) produces intermediate ELFs during `zig build`
    # that it execs directly — these lack codesign sections, so OHOS refuses to exec them.
    # binary-sign-tool each as AccessDenied errors surface; zig's cache (keyed by source hash)
    # tolerates it. Cold build converges after ~6 sign retries. Doesn't affect the final binary.
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

        # Path zig prints varies by emitting process's cwd; sign every matching basename
        # under .zig-cache/o/*/ (parallel build graph may produce multiple).
        basenames = output.scan(/([A-Za-z0-9_.-]+): AccessDenied/).flatten.uniq
        odie "cargo install failed (no AccessDenied path found):\n#{output}" if basenames.empty?

        signed_any = false
        basenames.each do |basename|
          Dir.glob("#{zig_cache_glob}/#{basename}").each do |candidate|
            next unless File.file?(candidate)

            next unless system "binary-sign-tool", "sign", "-selfSign", "1",
                               "-inFile", candidate, "-outFile", "#{candidate}.signed"

            mv "#{candidate}.signed", candidate
            chmod 0755, candidate
            signed_any = true
          end
        end
        odie "cargo install failed: no signable binaries matched #{basenames}:\n#{output}" unless signed_any
      end
    end

    # No ohos-shim wrapper: verified on real hardware that the full flow
    # (server, workspace/pane management, agent detection, session restart)
    # works without any shim interception — herdr hits none of its intercept
    # points (no temp_dir/hardlink/getpwuid/splice usage).
    generate_completions_from_executable(bin/"herdr", "completion")
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

    # Agent detection on OHOS relies on the tcgetpgrp fallback patched in above
    # (procfs reports no tty foreground group). A fake "opencode" process in a
    # pane must show up in the agent list.
    (testpath/"bin").mkpath
    fake_agent = testpath/"bin/opencode"
    fake_agent.write("#!/bin/sh\nsleep 60\n")
    fake_agent.chmod 0755

    output = shell_output("#{bin}/herdr pane list")
    pane_id = JSON.parse(output).dig("result", "panes", 0, "pane_id")
    shell_output("#{bin}/herdr pane run #{pane_id} #{fake_agent}")
    agents = ""
    20.times do
      agents = shell_output("#{bin}/herdr agent list")
      break if agents.include?('"opencode"')

      sleep 1
    end
    assert_match '"opencode"', agents
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
