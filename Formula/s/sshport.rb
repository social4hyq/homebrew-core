class Sshport < Formula
  desc "Forward a remote dev server's ports to identical local ports over SSH"
  homepage "https://github.com/social4hyq/ohos-sshport"
  url "https://github.com/social4hyq/ohos-sshport.git",
      revision: "ce0d279f655af31b51e7a83c8fb5925837c4f36a"
  version "0.1.3"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/sshport-v0.1.3-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b242bb2e2a42e67b282794e7f89ffdf90aa991449df8de7ade8b702565570260"
  end

  # sshport auto-forwards a remote Linux dev server's localhost:PORT
  # listeners to the identical localhost:PORT on this machine, tracked live
  # via a lightweight remote SSH polling loop — no ControlMaster/mux (this
  # OHOS filesystem rejects the hardlink() its unix-socket handshake needs),
  # one ssh -N -L child process per forwarded port, local port numbers are
  # never renumbered on conflict.
  #
  # Pure TypeScript, zero runtime npm dependencies (only @types/bun and
  # typescript as devDependencies, for `tsc --noEmit`) — `bun build
  # --target=bun` produces a single ~40KB JS bundle with no native .so, so
  # there is nothing here to codesign, unlike every other bun-based formula
  # in this tap.
  depends_on "bun"

  def install
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
    system "bun", "install", "--frozen-lockfile"
    system "bun", "build", "--target=bun", "--outfile", "sshport.js", "src/cli.ts"
    libexec.install "sshport.js"

    # $HOMEBREW_PREFIX is resolved at *runtime* inside the script, not
    # interpolated at build time (same pattern as opencode-shim.rb's
    # wrapper) — this is a plain shell script, not a binary being
    # RUNPATH-patched, so baking the build machine's prefix in here would
    # break portability the same way an absolute path would in any other
    # relocatable bottle.
    (bin/"sshport").write <<~SH
      #!/bin/sh
      : "${HOMEBREW_PREFIX:?sshport: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      exec "$HOMEBREW_PREFIX/opt/bun/bin/bun" "$HOMEBREW_PREFIX/opt/sshport/libexec/sshport.js" "$@"
    SH
    chmod 0755, bin/"sshport"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshport --version 2>&1")
    # `doctor` checks ssh/ssh-keygen presence and runs its own local
    # bind()-then-probe self-check (occupies an ephemeral port, confirms the
    # portguard module actually detects EADDRINUSE) — no network access, so
    # it's safe to run unconditionally in `brew test`.
    system bin/"sshport", "doctor"
  end
end
