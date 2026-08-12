class OhosBstLight < Formula
  desc "Lightweight binary self-sign tool for HarmonyOS (preserves ELF structure)"
  homepage "https://github.com/hqzing/ohos-bst-light"
  url "https://github.com/hqzing/ohos-bst-light.git",
      revision: "c4dfd71c869a0ca055d8b5ce4c3a9bf53735b2e1"
  version "1.0.0"
  license "MIT"
  revision 1

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-bst-light-v1.0.0-r1"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "3698df835d0a44e2262cc111908f26064648f6f5e652f2944edf17eb17595932"
  end

  # self-sign preserves ELF structure (binary-sign-tool can corrupt Bun binaries).
  depends_on "ohos-sdk" => :build

  def install
    # ENV.cc (superenv) is fine: self-sign needs only libc.so.
    system ENV.cc, "self-sign.c", "-o", "self-sign"
    bin.install "self-sign"
  end

  test do
    assert_path_exists bin/"self-sign"
  end
end
