class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI — HarmonyOS aarch64 (Linux musl binary + OHOS signing)"
  homepage "https://docs.anthropic.com/en/docs/claude-code"
  version "2.1.207"
  url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-#{version}.tgz"
  sha256 "6b76b77b3e5c1f05ceb898266db1cf603f67d5132b3c080ac6d63da9ed4cd6e1"
  license "Anthropic License"

  livecheck do
    url "https://www.npmjs.com/package/@anthropic-ai/claude-code-linux-arm64-musl"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/)
  end

  # Claude Code from 2.1.113+ only ships Bun-compiled binaries (no plain JS).
  # Use the linux-arm64-musl binary — musl ABI is compatible with OHOS.
  # Downloaded from official npm registry. Users behind GFW may set proxy via
  # ALL_PROXY / HTTP_PROXY environment variables, or use HOMEBREW_ARTIFACT_DOMAIN.
  depends_on "ohos-bst-light"  => :build
  depends_on "close-range-shim"

  def install
    claude_bin = buildpath.glob("package/claude").first || buildpath.glob("**/claude").first
    odie "claude binary not found in npm tarball" unless claude_bin

    system Formula["ohos-bst-light"].opt_bin/"self-sign", claude_bin.to_s

    libexec.install claude_bin => "claude"
    chmod 0755, libexec/"claude"

    (bin/"claude").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{Formula["close-range-shim"].opt_lib}/libclose_range_shim.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{libexec}/claude" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      Claude Code requires API credentials. Configure via environment variables:

        export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
        export ANTHROPIC_AUTH_TOKEN=sk-xxx
        export ANTHROPIC_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_EFFORT_LEVEL=max

      See https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code
      for DeepSeek integration details.

      For OpenAI-format APIs, install claude-code-router:
        brew install claude-code-router
    EOS
  end

  test do
    assert_path_exists libexec/"claude"
  end
end
