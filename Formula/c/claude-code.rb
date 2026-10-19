class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.292.tgz"
  sha256 "763250852824215ac3b02a5985688a742a243899ef689dd66c5b99a01f270003"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 8

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/stable"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.292-r9"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21b1d33e5ba079e17f5888083abd10f0d0a513c1a7a77e4b74b929c30c27dd1a"
  end

  depends_on "glibc"
  depends_on "node"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  conflicts_with "claude-code.latest", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write_env_script var/name/pkg_version/"claude",
                                  CLAUDE_CODE_TMPDIR: "${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
    package = "@anthropic-ai/claude-code-linux-arm64"
    (libexec/"package.json").write JSON.generate({
      private: true, dependencies: { package => version.to_s }
    })
    (libexec/"package-lock.json").write JSON.generate({
      lockfileVersion: 3,
      packages:        {
        ""                        => { dependencies: { package => version.to_s } },
        "node_modules/#{package}" => {
          version: version.to_s, resolved: stable.url,
          integrity: "sha256-#{[[stable.checksum.to_s].pack("H*")].pack("m0")}"
        },
      },
    })
    (libexec/"install-claude.sh").write <<~SH
      set -eu
      prefix="$1"
      target="$prefix/var/#{name}/#{pkg_version}"
      work=$(mktemp -d "$2/claude-install.XXXXXX")
      pending=""
      trap 'rm -rf "$work"; [ -z "$pending" ] || rm -f "$pending"' EXIT
      trap 'exit 1' HUP INT TERM
      cd "$work"
      cp "$(dirname "$0")/package.json" "$(dirname "$0")/package-lock.json" .
      PATH="$prefix/opt/node/bin:$PATH" "$prefix/opt/node/bin/npm" install \
        --os=linux --cpu=arm64 --libc=glibc --ignore-scripts --no-audit --no-fund \
        --strict-ssl=false --cache "$work/cache"
      mkdir -p "$target"
      pending=$(mktemp "$target/.claude.XXXXXX")
      cp node_modules/@anthropic-ai/claude-code-linux-arm64/claude "$pending"
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
