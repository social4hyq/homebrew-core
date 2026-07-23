class CcSwitch < Formula
  desc "AI coding CLI provider manager and local proxy — HarmonyOS aarch64 (prebuilt)"
  homepage "https://github.com/SaladDay/cc-switch-cli"
  url "https://github.com/SaladDay/cc-switch-cli/releases/download/v5.9.2/cc-switch-cli-v5.9.2-linux-arm64-musl.tar.gz"
  sha256 "2a94b345dd19dd63d1f1c9069e511aa6e0e09381c6ddb209e699a939becec9e2"
  license "MIT"
  # Official linux-arm64-musl release asset (Rust, fully static aarch64 ELF —
  # no INTERP/DYNAMIC segment per readelf -l). Named cc-switch, not
  # cc-switch-cli: official homebrew/core already ships a cc-switch-cli
  # formula for this same upstream, and per this tap's naming rule only
  # genuinely conflicting names get social4hyq/core/ qualification — picking
  # the free name keeps it bare. The binary installs as cc-switch either way.
  #
  # Primary use here: codex 0.145+ dropped wire_api="chat", so Chat-
  # Completions-only providers (Kimi K3, DeepSeek, ...) need cc-switch's
  # local proxy to translate the Responses API. Proxy verified listening on
  # 127.0.0.1:15721 on the real device 2026-07-23 (foreground `proxy serve`,
  # imported existing claude/codex configs, no sandbox issues — the
  # OfficeCLI-class prctl SIGSYS problem does not apply to this binary).
  #
  # SIGNING — self-sign only, binary-sign-tool corrupts this binary:
  # binary-sign-tool reports success on static ELFs but the result SIGSEGVs
  # at execve before the first syscall (verified 2026-07-23 against both
  # this binary and an unrelated static-musl ripgrep as control; the same
  # files signed with ohos-bst-light self-sign run clean). Like
  # codex/opencode/grok-build, must also be built with
  # HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset — install() self-signs, and CI's
  # auto-sign pass re-signing it corrupts the ELF. build.sh's
  # UNSET_SIGN_FORMULAS covers this in CI; the odie guard below catches any
  # other build path.

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "ohos-bst-light" => :build

  def install
    # Guard against the auto-sign pass corrupting this prebuilt binary —
    # same class of bug as codex/opencode/grok-build (see their install()
    # for the fuller writeup).
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "cc-switch must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass corrupts static ELFs (SIGSEGV at execve)"
    end

    src = buildpath/"cc-switch"
    odie "cc-switch binary not found at #{src}" unless src.exist?

    sign = formula_opt_bin("ohos-bst-light")/"self-sign"
    system sign, src.to_s

    mkdir_p libexec/"bin"
    libexec.install src => "bin/cc-switch"
    chmod 0755, libexec/"bin/cc-switch"

    # Self-reference via opt_libexec (prefix-relative, stable) rather than
    # libexec (Cellar-relative) — same HOMEBREW_CELLAR-flip reasoning as the
    # other OHOS CLI formulas in this tap (see opencode.rb).
    (bin/"cc-switch").write <<~SH
      #!/bin/sh
      export TMPDIR="${CC_SWITCH_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/cc-switch" "$@"
    SH
    chmod 0755, bin/"cc-switch"

    # Generate from the libexec binary: the bin/cc-switch wrapper execs
    # opt_libexec, whose opt/ symlink only exists after install.
    generate_completions_from_executable(libexec/"bin/cc-switch", "completions")
  end

  def caveats
    <<~EOS
      cc-switch stores its state in ~/.cc-switch and imports existing
      Claude Code / Codex / Gemini CLI configs on first run.

      To bridge codex to a Chat-Completions-only provider (Kimi, DeepSeek):
        cc-switch provider   # add the provider
        cc-switch proxy      # configure and enable the local proxy route

      Don't use cc-switch's self-update: this build is managed by Homebrew.
      Use `brew upgrade cc-switch` instead.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cc-switch --version 2>&1")
  end
end
