class CloseRangeShim < Formula
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
