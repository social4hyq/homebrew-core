class Herdr < Formula
  desc "Agent multiplexer that lives in your terminal"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr/archive/refs/tags/v0.9.3.tar.gz"
  sha256 "e48f6706440c92362773663131ef5b524c62549523e50a03f2b55d315edca100"
  license "Apache-2.0"
  revision 1
  head "https://github.com/herdrdev/herdr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-v0.9.3-r8"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6762540e7243dc3e236556175b129a89cabc73a325fd3dfc369408e169153277"
  end

  depends_on "rust" => :build
  # Upstream uses a zig formula; this tap has no zig formula, so OHOS stages the
  # official prebuilt static release as a build-only tool instead (see below).
  depends_on "zig@0.16" => :build unless OS.ohos?

  if OS.ohos?
    # herdr's vendored libghostty-vt requires Zig 0.16.0 (build.zig.zon
    # minimum_zig_version). This tap has no zig formula, so stage the official
    # prebuilt static release as a build-only tool instead (not distributed).
    resource "zig" do
      url "https://ziglang.org/download/0.16.0/zig-aarch64-linux-0.16.0.tar.xz"
      sha256 "ea4b09bfb22ec6f6c6ceac57ab63efb6b46e17ab08d21f69f3a48b38e1534f17"
    end

    # crates/ghostty-vt/build.rs's Rust-TARGET→zig-target table doesn't know OHOS; route onto musl.
    patch do
      file "Patches/herdr/0001-build-rs-zig-target-ohos.patch"
    end

    # OHOS procfs has no tty foreground group/task children; fall back to
    # tcgetpgrp() on the pane's own PTY master fd for agent detection.
    patch do
      file "Patches/herdr/0002-pane-agent-detection-tcgetpgrp.patch"
    end

    # Same procfs gap in the agent start/prompt gates, which look it up themselves.
    patch do
      file "Patches/herdr/0003-agent-gate-tty-foreground.patch"
    end

    # OHOS also never delivers SIGWINCH on PTY resize, so pane apps never learn
    # about layout changes; notify the foreground group explicitly after resize.
    patch do
      file "Patches/herdr/0004-pty-resize-notify-winch.patch"
    end

    # The OHOS terminal never answers the OSC 10/11 color queries, so pane
    # defaults stay white-on-black and reverse video (SGR 7, e.g. a TUI's mouse
    # selection highlight) resolves to black-on-white and disappears on a light
    # terminal; fall back to the configured app palette instead.
    patch do
      file "Patches/herdr/0005-host-theme-fallback.patch"
    end
  end

  deny_network_access!

  def fetch
    if OS.ohos?
      # zig finds lib/ via self-exe-realpath; keep the tree intact, on PATH.
      resource("zig").stage(buildpath/"zig-toolchain")
      ENV.prepend_path "PATH", (buildpath/"zig-toolchain").to_s

      # uucode dep fetch (deps.files.ghostty.org) is unreachable here; persist
      # the cache so it only needs to succeed once.
      ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s
    end

    system "cargo", "fetch", *std_cargo_fetch_args
    cd "vendor/libghostty-vt" do
      system "zig", "build", "--fetch=all"
    end
  end

  def install
    if OS.ohos?
      # The zig toolchain was staged in `fetch`; put it back on PATH.
      ENV.prepend_path "PATH", (buildpath/"zig-toolchain").to_s
      # Reuse the cache populated during `fetch` so the offline build works.
      ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s
    end

    system "cargo", "install", *std_cargo_args

    # No ohos-shim wrapper: hits none of its intercept points.
    generate_completions_from_executable(bin/"herdr", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/herdr --version")

    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["HERDR_CONFIG_PATH"] = (testpath/"config.toml").to_s
    ENV["HERDR_SOCKET_PATH"] = (testpath/"herdr.sock").to_s

    if OS.ohos?
      # OHOS has no isolated per-user temp dir in the test sandbox; keep the
      # server's temp files under testpath.
      ENV["TMPDIR"] = testpath.to_s
    end

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

    if OS.ohos?
      # Exercises the tcgetpgrp fallback: a fake opencode process must show up
      # in the agent list.
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

      assert_match "agent_prompted", shell_output("#{bin}/herdr agent prompt #{pane_id} hello")
    end
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
