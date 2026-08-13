class OhosBstLight < Formula
  desc "Lightweight binary self-sign tool for HarmonyOS (preserves ELF structure)"
  homepage "https://github.com/hqzing/ohos-bst-light"
  url "https://github.com/hqzing/ohos-bst-light/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "efd2a40d8b9436d6b404519283758f00b49f0b363c42cb0437d9b0856b2b2fe9"
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
