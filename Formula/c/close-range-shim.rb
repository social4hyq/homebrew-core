class CloseRangeShim < Formula
  # DEPRECATED — superseded by ohos-compat-shim (social4hyq/ohos-compat-shim),
  # a strict superset: identical close_range() / syscall(SYS_close_range) handling
  # (same probe-then-fallback pattern, this is its upstream), PLUS getpwuid_r,
  # tmpfile, getcwd and fchmodat2 interceptors that the same class of prebuilt
  # musl binaries also needs on OHOS. New formulae should `depends_on
  # "ohos-compat-shim"` instead. This formula is retained only so existing
  # `brew install close-range-shim` users are not broken; no formula in this
  # tap depends on it anymore (opencode, codex and claude-code all moved off it).
  desc "LD_PRELOAD shim to handle close_range syscall interception on HarmonyOS"
  homepage "https://github.com/hqzing/close-range-shim"
  url "https://github.com/hqzing/close-range-shim.git",
      revision: "f12b5227ac6c93a1a1689d850a1d4e41ec349b35"
  version "0.1.0"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/close-range-shim-v0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d393278a61518f3aa18554b4a250bfcaab52e0beec5316df34bdf2367cddb70"
  end

  livecheck do
    skip "development tool, manually versioned"
  end

  # HarmonyOS seccomp blocks close_range syscall. This shim intercepts it
  # before it reaches the kernel, providing a degraded fallback implementation.
  depends_on "ohos-sdk" => :build

  def install
    system "clang", "-shared", "-fPIC",
           "-o", "libclose_range_shim.so",
           "close_range_shim.c",
           "-O2", "-Wall", "-Wextra"
    lib.install "libclose_range_shim.so"
  end

  test do
    assert_path_exists lib/"libclose_range_shim.so"
  end
end
