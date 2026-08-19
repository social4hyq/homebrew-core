class Herdr < Formula
  desc "Terminal workspace runtime for AI coding agents (built from source)"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "47bdb0753beb8a6b157cf2fec26fbe6b787f85ffea0dde579b0001d6cd663572"
  license "Apache-2.0"
  revision 3
  head "https://github.com/herdrdev/herdr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-v0.8.0-r7"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "63d1c21e515e936c5c322f9a0c533bec1f67870e9e3e585bb39b0a4973fa5abc"
  end

  depends_on "rust" => :build
  depends_on "zig@0.15" => :build
  depends_on "ohos-compat-shim"

  def install
    ENV.prepend_path "PATH", formula_opt_bin("zig@0.15")

    # libghostty-vt's build.zig.zon has a non-lazy dep (uucode) fetched from deps.files.ghostty.org,
    # which is unreachable from this container. Persistent cache ensures the fetch only
    # needs to succeed once per machine.
    ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"herdr-zig-global-cache").to_s

    # build.rs maps Rust TARGET to zig -Dtarget via a fixed match table that panics on unknowns.
    # aarch64-unknown-linux-ohos isn't in it; route onto aarch64-linux-musl (same libc/ABI).
    # The static lib is plain object code linked by rustc's own linker, not zig.
    musl_arm = "\"aarch64-unknown-linux-musl\" => \"aarch64-linux-musl\","
    ohos_arm = "\"aarch64-unknown-linux-ohos\" => \"aarch64-linux-musl\","
    inreplace "build.rs", musl_arm, "#{musl_arm}\n        #{ohos_arm}"

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

    mkdir_p libexec/"bin"
    mv bin/"herdr", libexec/"bin/herdr"
    (bin/"herdr").write <<~SH
      #!/bin/sh
      exec "#{formula_opt_bin("ohos-compat-shim")}/ohos-shim" "#{opt_libexec}/bin/herdr" "$@"
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
