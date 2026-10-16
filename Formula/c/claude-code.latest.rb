class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.301.tgz"
  sha256 "b85a88e296a63ee407f7755eb9a1b071b2529f2adc39894148c127827a58e7d0"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 1

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.301-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71f7796a88f8a683a8558f671e556c74a10ffe240eaea034166cc3db6900f395"
  end

  depends_on "glibc"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write_env_script var/name/pkg_version/"claude",
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
  end

  def post_install
    stable.stage do
      system formula_opt_bin("patchelf")/"patchelf", "--set-interpreter",
             formula_opt_lib("glibc")/"ld-linux-aarch64.so.1", "claude"
      system formula_opt_bin("ohos-selfsign")/"selfsign", "claude"
      (var/name/pkg_version).install "claude"
    end
  end

  test do
    post_install unless (var/name/pkg_version/"claude").executable?
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
