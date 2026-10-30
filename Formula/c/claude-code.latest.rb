class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.314.tgz"
  sha256 "f0639b67e5a7131cad261f442b2b75244635bf24916bdad6ddc6df0f84b4aed4"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.314-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc7305b2b877796748a3724ddab58e3935251c7c76f023393ba4536fca20d810"
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"
  depends_on "pnpm"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -eu
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "$HOMEBREW_PREFIX/opt/ohos-compat-shim/bin/ohos-shim" \
        "$HOMEBREW_PREFIX/var/#{name}/#{pkg_version}/claude" "$@"
    SH
    chmod 0755, bin/"claude"

    package = "@anthropic-ai/claude-code-linux-arm64-musl"
    (libexec/"package.json").write JSON.generate({
      private: true, dependencies: { package => version.to_s }
    })
    (libexec/"pnpm-lock.yaml").write <<~YAML
      lockfileVersion: '9.0'

      settings:
        autoInstallPeers: true
        excludeLinksFromLockfile: false

      importers:
        .:
          dependencies:
            '#{package}':
              specifier: #{version}
              version: #{version}

      packages:
        '#{package}@#{version}':
          resolution: {integrity: sha256-#{[[stable.checksum.to_s].pack("H*")].pack("m0")}}
          cpu: [arm64]
          os: [linux]
          libc: [musl]

      snapshots:
        '#{package}@#{version}': {}
    YAML
    (libexec/"pnpm-workspace.yaml").write <<~YAML
      minimumReleaseAgeExclude:
        - '#{package}@#{version}'
    YAML
    (libexec/".npmrc").write "strict-ssl=false\n"
    (libexec/"install-claude.sh").write <<~SH
      set -eu
      prefix="$1"
      target="${3:-$prefix/var/#{name}/#{pkg_version}}"
      work=$(mktemp -d "$2/claude-install.XXXXXX")
      pending=""
      trap 'rm -rf "$work"; [ -z "$pending" ] || rm -f "$pending"' EXIT
      trap 'exit 1' HUP INT TERM
      cd "$work"
      cp "$(dirname "$0")/package.json" "$(dirname "$0")/pnpm-lock.yaml" "$(dirname "$0")/pnpm-workspace.yaml" "$(dirname "$0")/.npmrc" .
      "$prefix/opt/pnpm/bin/pnpm" install --frozen-lockfile \
        --os=linux --cpu=arm64 --libc=musl --ignore-scripts \
        --store-dir "$work/store"
      mkdir -p "$target"
      pending=$(mktemp "$target/.claude.XXXXXX")
      cp node_modules/#{package}/claude "$pending"
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
    system "/usr/bin/sh", libexec/"install-claude.sh", HOMEBREW_PREFIX, testpath, testpath/"runtime"
    assert_match "#{version} (Claude Code)",
                 shell_output("#{formula_opt_bin("ohos-compat-shim")}/ohos-shim #{testpath}/runtime/claude --version")
  end
end
