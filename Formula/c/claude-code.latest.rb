class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.302.tgz"
  sha256 "8a3be117b2d679bba24ec14fc64906280c6a993944a036a70c4b675f5ada5e33"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.301-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e819d012aa7827ba19786256d09d34eb1a7609b1a03745ad7654e74d9932ca7e"
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
