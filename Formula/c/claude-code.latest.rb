class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.302.tgz"
  sha256 "8a3be117b2d679bba24ec14fc64906280c6a993944a036a70c4b675f5ada5e33"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 2

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.302-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92678e6ab80e4dae8af84426d5a6c212ab2bfce3eb322d935f5a3979857b9aa7"
  end

  depends_on "glibc"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (libexec/"install-claude").write <<~SH
      #!/bin/sh
      set -eu
      dest="$1"
      patchelf="$2"
      interpreter="$3"
      signer="$4"
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT HUP INT TERM
      curl -fL --retry 3 -o "$work/package.tgz" "#{stable.url}"
      echo "#{stable.checksum}  $work/package.tgz" | sha256sum -c -
      tar -xzf "$work/package.tgz" -C "$work"
      "$patchelf" --set-interpreter "$interpreter" "$work/package/claude"
      "$signer" "$work/package/claude"
      mkdir -p "$dest"
      cp "$work/package/claude" "$dest/claude.new"
      chmod +x "$dest/claude.new"
      mv -f "$dest/claude.new" "$dest/claude"
    SH
    chmod 0755, libexec/"install-claude"
    (bin/"claude").write_env_script var/name/pkg_version/"claude",
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
  end

  post_install_steps do
    run "install-claude", base: :libexec,
                          args: ["{{var}}/claude-code.latest/{{version}}",
                                 "{{HOMEBREW_PREFIX}}/opt/patchelf/bin/patchelf",
                                 "{{HOMEBREW_PREFIX}}/opt/glibc/lib/ld-linux-aarch64.so.1",
                                 "{{HOMEBREW_PREFIX}}/opt/ohos-selfsign/bin/selfsign"],
                          writable_paths: ["claude-code.latest"], writable_base: :var,
                          network_access: true
  end

  test do
    run_post_install_steps unless (var/name/pkg_version/"claude").executable?
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
