class Reasonix < Formula
  desc "DeepSeek-native AI coding agent for the terminal (HarmonyOS aarch64)"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.21.3.tar.gz"
  sha256 "ca1d9d7e99b1acd3db7ef3e7efe19dfe9bccfa7cd44b62145989fa0b46413d96"
  license "MIT"

  # The repo also ships a separate Electron-ish desktop app tagged
  # `desktop-vX.Y.Z` (release `prerelease: false`, so it isn't filtered by
  # that check alone) and CLI prereleases tagged `vX.Y.Z-preview.N`. Both
  # would otherwise satisfy GithubReleases's default `v?(\d+(?:\.\d+)+)`
  # regex (it does an unanchored substring search), so `/releases/latest`
  # and the default regex are both unusable here — anchor the regex to
  # accept only exactly `vX.Y[.Z...]` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/reasonix-v1.21.2-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adce33f000765b2efd318fb7c0940a5817978f106fc7fca6d7cf4e4c52d99098"
  end

  # No `bottle do` block yet — bottle-build.yml publishes it and writes
  # root_url/sha256 back onto this file as part of the PR (see sshport's
  # initial commit, c51fb9f99, for the same shape).

  depends_on "go" => :build
  # CGO_ENABLED=0 below means the actual build never invokes a C compiler,
  # but Homebrew's superenv setup unconditionally runs CompilerSelector
  # before any formula's install() (even Go-only ones) and hard-errors if
  # it can't find one among this formula's declared deps + system PATH —
  # same reason bun.rb declares this despite being a separate Rust build.
  # It also supplies llvm-strip, used below to remove go's own .codesign
  # section before self-sign.
  depends_on "llvm@21" => :build
  depends_on "ohos-bst-light" => :build

  def install
    # This tap's `go` already patches the toolchain to unconditionally embed
    # a `.codesign` (content-integrity) section at link time, even for a
    # pure CGO_ENABLED=0 static build — confirmed via `readelf -S` on the
    # freshly linked binary before anything in this install() touches it.
    # That's the *first* of this tap's two OHOS signing layers (see
    # CLAUDE.md's "二进制签名两层"). The *second* layer — the
    # execution-permission signature — is normally applied automatically by
    # Homebrew's own post-install `sign_ohos_bottle_binaries` step
    # (formula_installer.rb), gated on HOMEBREW_OHOS_BOTTLE_BINARY_SIGN.
    # That step does `llvm-strip --remove-section=.codesign` then
    # `binary-sign-tool -selfSign 1` on every ELF in the keg — but
    # binary-sign-tool corrupts genuinely static ELFs with no PT_INTERP/
    # PT_DYNAMIC segment (confirmed: exec → permission-denied/SIGSEGV on a
    # doubly-processed copy of this exact binary), the same failure mode
    # documented for grok-build's prebuilt static release binary. A
    # CGO_ENABLED=0 Go binary has that exact static shape, so it needs the
    # same treatment: build with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset
    # (UNSET_SIGN_FORMULAS in build.sh covers CI) and do the execution-
    # permission signing here instead, via ohos-bst-light's `self-sign`
    # (proven safe on this exact static-ELF shape — see grok-build.rb).
    # self-sign itself refuses to touch a binary that already carries a
    # `.codesign` section ("this tool only adds a signature, it does not
    # strip old ones"), so the toolchain's own first-layer section has to
    # be stripped first — same `llvm-strip --remove-section=.codesign` verb
    # Homebrew's own automatic pass uses, just followed by self-sign
    # instead of binary-sign-tool for the second layer.
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "reasonix must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): Homebrew's " \
           "automatic binary-sign-tool pass corrupts this static Go binary"
    end

    # OHOS's /tmp is a read-only, root-owned directory in this app sandbox.
    # configEditLockRegistryDir() (internal/config/mutate.go) hardcodes the
    # config-edit advisory-lock directory to /tmp on every non-Windows GOOS,
    # with a comment explaining this is deliberate — the OS-wide temp root
    # is meant to stay invariant across per-process TMPDIR overrides, so a
    # wrapper-set TMPDIR alone does not reach it. Confirmed on-device: every
    # invocation printed two "lock config edits: ... read-only file system"
    # warnings, and anything that writes config (`setup`, `config *`,
    # `mcp add|remove|import`, `subagent create|edit|delete`) hard-errored.
    # The binary is a static ELF, so LD_PRELOAD via ohos-compat-shim (this
    # tap's usual fallback for OS assumptions baked into third-party
    # binaries) cannot intercept anything here either — patching the one
    # hardcoded path at the source is the only option. Swapping in
    # os.TempDir() (the file already `import "os"`) respects TMPDIR like
    # every other temp path in the codebase, and the bin/ wrapper below
    # pins TMPDIR to a fixed writable directory so the lock registry stays
    # one shared path per machine/user, same as upstream intended.
    inreplace "internal/config/mutate.go",
              'filepath.Join(string(filepath.Separator), "tmp", fmt.Sprintf("reasonix-config-locks-%x"',
              'filepath.Join(os.TempDir(), fmt.Sprintf("reasonix-config-locks-%x"'

    # Source comes from the GitHub archive tarball, not a git checkout, so
    # there is no .git/ to read a commit SHA from — linkedRevision (an
    # informational diagnostics field only, see productdocs.linkedRevision)
    # is left at its zero-value default rather than faked.
    ENV["CGO_ENABLED"] = "0"
    ldflags = "-s -w -X main.version=v#{version} " \
              "-X reasonix/internal/productdocs.linkedVersion=v#{version}"
    mkdir_p libexec/"bin"
    system "go", "build", *std_go_args(output: libexec/"bin/reasonix", ldflags:), "./cmd/reasonix"

    system "llvm-strip", "--remove-section=.codesign", (libexec/"bin/reasonix").to_s
    system formula_opt_bin("ohos-bst-light")/"self-sign", (libexec/"bin/reasonix").to_s

    # Self-reference via opt_libexec (prefix-relative, stable across
    # Cellar/HOMEBREW_CELLAR relocation) rather than libexec — same
    # reasoning as grok-build.rb / opencode@2.rb. TMPDIR is force-set
    # (not just defaulted) so every reasonix invocation on this machine
    # shares one config-lock registry path regardless of caller env.
    (bin/"reasonix").write <<~SH
      #!/bin/sh
      export TMPDIR="${REASONIX_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/reasonix" "$@"
    SH
    chmod 0755, bin/"reasonix"
  end

  def caveats
    <<~EOS
      Reasonix needs a DeepSeek API key:
        export DEEPSEEK_API_KEY=sk-xxx

      `sandbox.bash` reports unavailable on HarmonyOS (`reasonix doctor --json`
      → sandbox.available: false) — OHOS provides no Landlock/namespace
      primitive for it, same limitation as grok-build's sandbox modes. Bash
      tool calls still run, just without that extra confinement layer.

      Don't run `reasonix upgrade`: it would fetch an unsigned upstream
      binary and overwrite this Homebrew-managed, self-signed one. Use
      `brew upgrade reasonix` instead.
    EOS
  end

  test do
    assert_match "reasonix v#{version}", shell_output("#{bin}/reasonix --version")
    doctor = shell_output("#{bin}/reasonix doctor --json")
    assert_match "\"os\": \"linux\"", doctor
    assert_match "\"arch\": \"arm64\"", doctor
    # Regression guard for the /tmp lock-registry fix above: this must exit
    # 0, not "lock config edits: ... read-only file system".
    system bin/"reasonix", "config", "telemetry", "off"
  end
end
