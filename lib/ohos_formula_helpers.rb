# frozen_string_literal: true

# Shared conventions for the OHOS CLI formulas in this tap
# (opencode / codex / grok-build / ohos-opencode / claude-code).
#
# ── Why every CLI installs a bin/ shell wrapper exec'ing an opt_libexec path ──
# The real binary lives in libexec; bin/<name> is a wrapper that execs it via
# opt_libexec (HOMEBREW_PREFIX/opt/<formula>/libexec), NOT via the
# Cellar-absolute libexec path. HOMEBREW_CELLAR flips between
# HOMEBREW_PREFIX/Cellar and HOMEBREW_REPOSITORY/Cellar depending on which
# happens to exist at brew startup (see brew.sh) — a bottle that baked the
# build machine's Cellar-absolute path breaks when poured on a machine where
# that resolved the other way ("inaccessible or not found", shipped in
# opencode r0). opt/<name> is always HOMEBREW_PREFIX-relative and re-linked
# on every install, so it is stable across that flip. The same reasoning
# applies to DT_RUNPATH values (see opencode.rb). Verified 2026-07-14.
#
# ── Why TMPDIR defaults to an EL2 cache path ──
# OHOS /tmp is read-only in app contexts; the wrapper defaults TMPDIR to the
# writable EL2 path below, overridable per-CLI via <NAME>_TMPDIR.
module OhosFormulaHelpers
  OHOS_DEFAULT_TMPDIR = "/data/storage/el2/base/cache"

  module_function

  # Standard bin/ wrapper for a prebuilt/compiled CLI.
  # Line order is fixed (and load-bearing for bottle reproducibility):
  # shebang → LD_PRELOAD (if any) → TMPDIR default → extra exports → exec.
  #
  #   target        - absolute path the wrapper execs (use an opt_libexec
  #                   path, see header comment)
  #   tmpdir_env    - user-facing override variable, e.g. "CODEX_TMPDIR"
  #   preload       - LD_PRELOAD .so paths, chained ahead of any inherited
  #                   LD_PRELOAD
  #   extra_exports - verbatim extra export lines, emitted after TMPDIR
  def cli_wrapper(target, tmpdir_env:, preload: [], extra_exports: [])
    lines = ["#!/bin/sh"]
    lines << "export LD_PRELOAD=\"#{preload.join(":")}${LD_PRELOAD:+:$LD_PRELOAD}\"" unless preload.empty?
    lines << "export TMPDIR=\"${#{tmpdir_env}:-#{OHOS_DEFAULT_TMPDIR}}\""
    lines.concat(extra_exports)
    lines << "exec \"#{target}\" \"$@\""
    "#{lines.join("\n")}\n"
  end
end
