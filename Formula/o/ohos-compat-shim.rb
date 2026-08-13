class OhosCompatShim < Formula
  desc "LD_PRELOAD compat shim for HarmonyOS-sandboxed aarch64/musl binaries"
  homepage "https://github.com/social4hyq/ohos-compat-shim"
  url "https://github.com/social4hyq/ohos-compat-shim.git",
      tag: "v0.2.9", revision: "54bbffbaa43f03ed765092c0f32be47962135e79"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-compat-shim-v0.2.9-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d045ef197c73efc2d2735913503ddf2d790afc2dd878b7034d40a8a2e8d6c932"
  end

  # HarmonyOS sandbox seccomp-filters close_range/fchmodat2 and returns unexpected
  # errno from getpwuid_r/tmpfile/getcwd/splice. Shim intercepts at libc-symbol level,
  # falls back only on the documented symptom (safe no-op elsewhere).
  depends_on "ohos-sdk" => :build

  def install
    # Bypass superenv cc shim (injects DT_RUNPATH making bottle non-relocatable);
    # this .so only needs libc/libdl from the preloading host.
    clang = formula_opt_bin("ohos-sdk")/"clang"
    system clang, "-shared", "-fPIC",
           "-o", "libohos_compat.so",
           "src/ohos_compat_shim.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    lib.install "libohos_compat.so"

    # Companion .so for ohos-compat-check's dlopen/.dynsym probe (see src/checkdep.c).
    system clang, "-shared", "-fPIC",
           "-o", "libohos_compat_checkdep.so",
           "src/checkdep.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    lib.install "libohos_compat_checkdep.so"

    # `ohos-shim check` probes whether each symptom is still reproducible on this device,
    # so HarmonyOS 7.0+ can discover which OHOS_COMPAT_SHIM_DISABLE entries are safe.
    system clang, "-rdynamic", "-pthread",
           "-o", "ohos-compat-check",
           "src/ohos_compat_check.c",
           "-O2", "-Wall", "-Wextra", "-ldl"
    libexec.install "ohos-compat-check"

    # Launcher: `ohos-shim <cmd>` preloads the shim; `ohos-shim check` runs the probe.
    # Resolves .so/check binary via ../lib/../libexec relative to itself.
    bin.install "bin/ohos-shim"

    # Source-only install so check sources can be built on machines without harmonybrew.
    pkgshare.install "src/ohos_compat_check.c", "src/checkdep.c"
  end

  test do
    assert_path_exists lib/"libohos_compat.so"
    assert_path_exists lib/"libohos_compat_checkdep.so"
    assert_path_exists libexec/"ohos-compat-check"
    assert_match "usage: ohos-shim", shell_output("#{bin}/ohos-shim 2>&1", 64)
    # `check` verdicts depend on real device sandbox behavior (CI differs from hardware),
    # so only assert it runs and produces a report.
    assert_match "OHOS_COMPAT_SHIM_DISABLE=", shell_output("#{bin}/ohos-shim check --rounds 1")
  end
end
