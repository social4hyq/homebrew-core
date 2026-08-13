class Sshport < Formula
  desc "Forward a remote dev server's ports to identical local ports over SSH"
  homepage "https://github.com/social4hyq/ohos-sshport"
  url "https://github.com/social4hyq/ohos-sshport/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "5e8acfa659110daf8fe84e7fcc8242b0e03c746fc219d06c4b488d551e666821"
  license "MIT"
  revision 1

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/sshport-v0.2.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2c7e59378a4977d6d83879527f41c8561999588e3dd2a9fb7896e6c3e4562846"
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

    # opt_libexec keeps the baked path stable across Cellar layout changes (same pattern
    # used throughout this tap, e.g. zellij.rb).
    (bin/"sshport").write_env_script formula_opt_bin("bun")/"bun", [opt_libexec/"sshport.js"], {}
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshport --version 2>&1")
    # `doctor` is local-only (bind probe, no network); safe in brew test.
    system bin/"sshport", "doctor"
  end
end
