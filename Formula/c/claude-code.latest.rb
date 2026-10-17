class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.302.tgz"
  sha256 "ee76ceb9b79b3b975f86c2726b9f57ed216916de1d78d54daa5cd5ec9374c568"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (libexec/"install-claude").write <<~SH
      #!/bin/sh
      set -eu
      dest="$1"
      signer="$2"
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT HUP INT TERM
      curl -fL --retry 3 -o "$work/package.tgz" "#{stable.url}"
      echo "#{stable.checksum}  $work/package.tgz" | sha256sum -c -
      tar -xzf "$work/package.tgz" -C "$work"
      "$signer" "$work/package/claude"
      mkdir -p "$dest"
      cp "$work/package/claude" "$dest/claude.new"
      chmod +x "$dest/claude.new"
      mv -f "$dest/claude.new" "$dest/claude"
    SH
    chmod 0755, libexec/"install-claude"
    (bin/"claude").write_env_script formula_opt_bin("ohos-compat-shim")/"ohos-shim",
                                  ["--", var/name/pkg_version/"claude"],
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
  end

  post_install_steps do
    run "install-claude", base: :libexec,
                          args: ["{{var}}/claude-code.latest/{{version}}",
                                 "{{HOMEBREW_PREFIX}}/opt/ohos-selfsign/bin/selfsign"],
                          writable_paths: ["claude-code.latest"], writable_base: :var,
                          network_access: true
  end

  test do
    run_post_install_steps unless (var/name/pkg_version/"claude").executable?
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
