class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.301.tgz"
  sha256 "d27ad4a8b40f52ddb9ad7952fda14f794198740980b2f5a133d8e8d5f7a5068e"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 2

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.301-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e819d012aa7827ba19786256d09d34eb1a7609b1a03745ad7654e74d9932ca7e"
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write_env_script formula_opt_bin("ohos-compat-shim")/"ohos-shim",
                                  ["--", var/name/pkg_version/"claude"],
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
  end

  def post_install
    stable.stage do
      system formula_opt_bin("ohos-selfsign")/"selfsign", "claude"
      (var/name/pkg_version).install "claude"
    end
  end

  test do
    post_install unless (var/name/pkg_version/"claude").executable?
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
