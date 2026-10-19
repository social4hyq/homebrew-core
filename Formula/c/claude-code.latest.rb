class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.303.tgz"
  sha256 "2cb67cd847c0551660c79f8412f7a98209bf3ee92fee642aa379585277428f88"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.302-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0354e354eea75690aed6cbed550bad6685a8b81305f67123920c1c4a42e979de"
  end

  depends_on "coreutils"
  depends_on "curl"
  depends_on "glibc"
  depends_on "gnu-tar"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write_env_script var/name/pkg_version/"claude",
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
    (libexec/"install-claude.sh").write <<~SH
      set -eu
      prefix="$1"
      target="$prefix/var/#{name}/#{pkg_version}"
      work=$(mktemp -d "$2/claude-install.XXXXXX")
      pending=""
      trap 'rm -rf "$work"; [ -z "$pending" ] || rm -f "$pending"' EXIT
      trap 'exit 1' HUP INT TERM
      cd "$work"
      "$prefix/opt/curl/bin/curl" -fL --retry 3 --retry-all-errors --connect-timeout 30 --max-time 600 \
        --proto '=https' --proto-redir '=https' -o archive.tgz #{stable.url.shellescape}
      printf '%s  archive.tgz\\n' #{stable.checksum.to_s.shellescape} | "$prefix/opt/coreutils/bin/sha256sum" -c -
      mkdir -p "$target"
      pending=$(mktemp "$target/.claude.XXXXXX")
      "$prefix/opt/gnu-tar/bin/tar" -xOf archive.tgz package/claude > "$pending"
      "$prefix/opt/patchelf/bin/patchelf" --set-interpreter "$prefix/opt/glibc/lib/ld-linux-aarch64.so.1" "$pending"
      "$prefix/opt/ohos-selfsign/bin/selfsign" "$pending"
      chmod +x "$pending"
      mv -f "$pending" "$target/claude"
    SH
  end

  post_install_steps do
    run "/usr/bin/sh",
        args: ["{{libexec}}/install-claude.sh", "{{HOMEBREW_PREFIX}}", "{{temp}}"],
        writable_paths: ["{{var}}/{{formula_name}}", "{{temp}}"], network_access: true
  end

  test do
    run_post_install_steps unless (var/name/pkg_version/"claude").executable?
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
