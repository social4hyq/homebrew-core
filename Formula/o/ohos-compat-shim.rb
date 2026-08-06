class OhosCompatShim < Formula
  desc "LD_PRELOAD compat shim for HarmonyOS-sandboxed aarch64/musl binaries"
  homepage "https://github.com/social4hyq/ohos-compat-shim"
  # `branch:` is required, not cosmetic: without it Homebrew's git downloader
  # falls back to `default_refspec` -> `git remote set-head origin --auto`
  # (GitHubGitDownloadStrategy#default_branch) to resolve which branch the
  # revision lives on -- a network round-trip through the container's
  # ghfast.top proxy, on every install, even when the revision is already
  # cached locally. Naming the branch explicitly (this repo's default is
  # `main`) skips that call entirely, same as bun.rb's `branch:
  # "ohos-aarch64"`. Found 2026-08-04 when ghfast.top was down and installs
  # failed here specifically, not at the actual clone/checkout.
  # 6349deb: "feat: add `ohos-shim check` -- on-device regression probe for
  # every interceptor" -- adds src/ohos_compat_check.c + src/checkdep.c +
  # bin/ohos-shim's `check` subcommand.
  url "https://github.com/social4hyq/ohos-compat-shim.git",
      revision: "6349deb19d3be02f86ad45220ee9eeb6a977595c", branch: "main"
  version "0.2.8"
  license "MIT"
  # No `revision N` here -- that's for same-version content bumps
  # (feedback_formula_revision_review); a version bump starts fresh.

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-compat-shim-v0.2.8-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93c37553a0bc9a6ef567e242f71473cdf7731b68beaecd4cd030e7e6c503e94e"
  end

  # No `bottle do` block: 0.2.8 adds new build artifacts (ohos-compat-check,
  # libohos_compat_checkdep.so), so the 0.2.7 bottle's sha256 no longer
  # applies. CI's bottle-build.yml regenerates this block against the pushed
  # revision -- don't hand-guess a sha256 here.

  # HarmonyOS's application sandbox seccomp-filters several Linux syscalls
  # (close_range, fchmodat2) and returns unexpected errno from a few libc
  # calls (getpwuid_r, tmpfile, getcwd, splice) that prebuilt musl binaries
  # assume work. This shim intercepts the libc-symbol level of those calls
  # and falls back to a userspace implementation when the real one fails in
  # the HarmonyOS-specific way — design rule is "prefer the real impl via
  # dlsym(RTLD_NEXT), fall back only on the documented symptom", so it's a
  # safe no-op on any target where the real call already works.
  depends_on "ohos-sdk" => :build

  def install
    # Use ohos-sdk's clang by absolute path, bypassing Homebrew's superenv cc
    # shim — it injects a DT_RUNPATH at HOMEBREW_CELLAR/lib and
    # HOMEBREW_PREFIX/lib, which makes the bottle non-relocatable. This .so
    # only needs libc/libdl (resolved by the preloading host process), so no
    # RUNPATH is wanted at all.
    clang = formula_opt_bin("ohos-sdk")/"clang"
    system clang, "-shared", "-fPIC",
           "-o", "libohos_compat.so",
           "src/ohos_compat_shim.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    lib.install "libohos_compat.so"

    # Tiny companion .so for ohos-compat-check's dlopen/.dynsym probe --
    # see src/checkdep.c's header comment for why this has to be a real
    # separately-dlopen()'d module, not just a function in the check binary.
    system clang, "-shared", "-fPIC",
           "-o", "libohos_compat_checkdep.so",
           "src/checkdep.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    lib.install "libohos_compat_checkdep.so"

    # `ohos-shim check` -- probes on THIS device whether the symptoms above
    # are still reproducible, so a HarmonyOS 7.0+ machine (where some of
    # these sandbox restrictions are expected to relax over time) can find
    # out which OHOS_COMPAT_SHIM_DISABLE entries are actually safe, instead
    # of guessing from this formula's HarmonyOS-6.1-era doc comments.
    # -rdynamic exports ohos_check_marker() so checkdep.so's dlopen probe
    # can look for it.
    system clang, "-rdynamic", "-pthread",
           "-o", "ohos-compat-check",
           "src/ohos_compat_check.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    libexec.install "ohos-compat-check"

    # Generic launcher: `ohos-shim <command> [args...]` preloads the shim
    # and execs; `ohos-shim check [...]` runs ohos-compat-check instead.
    # Resolves both the .so and the check binary via ../lib / ../libexec
    # relative to itself (this formula's own bin+lib+libexec layout) with a
    # $HOMEBREW_PREFIX fallback, so it works installed or copied standalone.
    # Generalizes examples/opencode-wrapper.sh (one target hardcoded per
    # copy) into a single reusable command.
    bin.install "bin/ohos-shim"

    # Source-only install so ohos_compat_check.c + checkdep.c can be scp'd
    # to a machine that doesn't have harmonybrew installed and built there
    # directly with OHOS NDK clang (see Makefile's `check` target) --
    # exactly the "check a HarmonyOS 7.0 device that has no formula on it
    # yet" use case this was added for.
    pkgshare.install "src/ohos_compat_check.c", "src/checkdep.c"
  end

  test do
    assert_path_exists lib/"libohos_compat.so"
    assert_path_exists lib/"libohos_compat_checkdep.so"
    assert_path_exists libexec/"ohos-compat-check"
    assert_match "usage: ohos-shim", shell_output("#{bin}/ohos-shim 2>&1", 64)
    # `check`'s actual NEEDED/DROPPABLE verdicts depend on the real device's
    # sandbox behavior (this CI container's results legitimately differ from
    # real HarmonyOS hardware -- that's the whole point of the tool), so
    # this only asserts it runs to completion and produces a report, not any
    # specific verdict.
    assert_match "OHOS_COMPAT_SHIM_DISABLE=", shell_output("#{bin}/ohos-shim check --rounds 1")
  end
end
