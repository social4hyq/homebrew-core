class Herdr < Formula
  desc "Agent multiplexer that lives in your terminal"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "1e83bff4b05834ed8281e16f1680e8f3e58375a94b2e3f2b3d021e28e293ef9a"
  license "Apache-2.0"
  head "https://github.com/herdrdev/herdr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-v0.9.0-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10e2d521144e8541261a73170ae374b414e3a65ca9bbf5e7363e892ed8ad7d7a"
  end

  depends_on "rust" => :build

  # zig 0.15.2 needs LLVM 20.x; this tap only has llvm@21. Stage the official
  # prebuilt static release as a build-only tool instead (not distributed).
  resource "zig" do
    url "https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz"
    sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  end

  # build.rs's Rust-TARGET→zig-target table doesn't know OHOS; route onto musl.
  patch do
    file "Patches/herdr/build-rs-zig-target-ohos.patch"
  end

  # OHOS procfs has no tty foreground group/task children; fall back to
  # tcgetpgrp() on the pane's own PTY master fd for agent detection.
  patch do
    file "Patches/herdr/pane-agent-detection-tcgetpgrp.patch"
  end

  # Same procfs gap in the agent start/prompt gates, which look it up themselves.
  patch do
    file "Patches/herdr/agent-gate-tty-foreground.patch"
  end

  def install
    # zig finds lib/ via self-exe-realpath; keep the tree intact, on PATH.
    resource("zig").stage(buildpath/"zig-toolchain")
    ENV.prepend_path "PATH", (buildpath/"zig-toolchain").to_s

    # uucode dep fetch (deps.files.ghostty.org) is unreachable here; persist
    # the cache so it only needs to succeed once.
    ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s

    system "cargo", "install", *std_cargo_args

    # No ohos-shim wrapper: hits none of its intercept points.
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

    assert_match "agent_prompted", shell_output("#{bin}/herdr agent prompt #{pane_id} hello")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
