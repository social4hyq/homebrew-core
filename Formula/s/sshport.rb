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
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/sshport-v0.2.1-r7"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b542a16c6115539bafe7ddf56dd13aa518e62962a33e77673f26bf3ccc16e36"
  end

  # Auto-forwards a remote dev server's ports to identical local ports.
  # Pure TypeScript, zero runtime npm deps — bun build --target=bun produces a
  # single JS bundle with no native .so, so nothing to codesign.
  depends_on "ccache" => :build
  depends_on "bun"

  def install
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
    system "bun", "install", "--frozen-lockfile"
    system "bun", "build", "--target=bun", "--outfile", "sshport.js", "src/cli.ts"
    libexec.install "sshport.js"

    # ccache probe (temporary): verify CCACHE_* passthrough through superenv and
    # ccache hit rate. Objects are not installed; the artifact is unchanged.
    ENV["CCACHE_DIR"] = (HOMEBREW_CACHE/"ccache-probe").to_s
    ohai "ccache probe: CCACHE_* seen by install:"
    system "sh", "-c", "env | grep '^CCACHE_' || echo '(no CCACHE_* vars)'"
    (buildpath/"ccache_probe.c").write "int ccache_probe(void) { return 42; }\n"
    system "ccache", ENV.cc, "-c", "-o", "probe1.o", "ccache_probe.c"
    system "ccache", ENV.cc, "-c", "-o", "probe2.o", "ccache_probe.c"
    system "ccache", "-s"

    (bin/"sshport").write_env_script(formula_opt_bin("bun")/"bun", opt_libexec/"sshport.js", {})
    chmod 0755, bin/"sshport"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshport --version 2>&1")
    # `doctor` is local-only (bind probe, no network); safe in brew test.
    system bin/"sshport", "doctor"
  end
end
