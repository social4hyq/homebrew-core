class OhosCompatShim < Formula
  desc "LD_PRELOAD compat shim for HarmonyOS-sandboxed aarch64/musl binaries"
  homepage "https://github.com/social4hyq/ohos-compat-shim"
  url "https://github.com/social4hyq/ohos-compat-shim.git",
      revision: "24c8aeeebcd11b01176ba9a83172057cba8d843d"
  version "0.2.2"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-compat-shim-v0.2.2-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "642fda3f97c6d9d7876eff0afa50736ac991d0a5724e92b78218a0e6697ee8ae"
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
  end

  test do
    assert_path_exists lib/"libohos_compat.so"
  end
end
