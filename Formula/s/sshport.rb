class Sshport < Formula
  desc "Forward a remote dev server's ports to identical local ports over SSH"
  homepage "https://github.com/social4hyq/ohos-sshport"
  url "https://github.com/social4hyq/ohos-sshport.git",
      tag: "v0.2.1", revision: "33b51319e55186ef85c0add720b2d34797297c62"
  license "MIT"
  revision 2

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/sshport-v0.2.1-r5"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59b8df5151b8b34eefcb8795df5ccfb408a6fed73f63b9551631bb807b7ce274"
  end

  # Auto-forwards a remote dev server's ports to identical local ports.
  # Pure TypeScript, zero runtime npm deps — bun build --target=bun produces a
  # single JS bundle with no native .so, so nothing to codesign.
  depends_on "bun"

  def install
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
    system "bun", "install", "--frozen-lockfile"
    system "bun", "build", "--target=bun", "--outfile", "sshport.js", "src/cli.ts"
    libexec.install "sshport.js"

    (bin/"sshport").write_env_script(formula_opt_bin("bun")/"bun", opt_libexec/"sshport.js", {})
    chmod 0755, bin/"sshport"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshport --version 2>&1")
    # `doctor` is local-only (bind probe, no network); safe in brew test.
    system bin/"sshport", "doctor"
  end
end
