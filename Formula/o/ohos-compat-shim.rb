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
  url "https://github.com/social4hyq/ohos-compat-shim.git",
      revision: "362bdf71e7b8c93db2dde1c01a0d334edbb36561", branch: "main"
  version "0.2.7"
  license "MIT"
  revision 1

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-compat-shim-v0.2.7-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0ee45e49064165c749b599cca411b53bebed3becf377042110d32086588194a"
  end

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
    # Generic launcher: `ohos-shim <command> [args...]` preloads the shim
    # and execs. Resolves the .so via ../lib relative to itself (this
    # formula's own bin+lib layout) with a $HOMEBREW_PREFIX fallback, so it
    # works installed or copied standalone. Generalizes
    # examples/opencode-wrapper.sh (one target hardcoded per copy) into a
    # single reusable command.
    bin.install "bin/ohos-shim"
  end

  test do
    assert_path_exists lib/"libohos_compat.so"
    assert_match "usage: ohos-shim", shell_output("#{bin}/ohos-shim 2>&1", 64)
  end
end
