class OhosBstLight < Formula
  desc "Lightweight binary self-sign tool for HarmonyOS (preserves ELF structure)"
  homepage "https://github.com/hqzing/ohos-bst-light"
  url "https://github.com/hqzing/ohos-bst-light.git",
      revision: "c4dfd71c869a0ca055d8b5ce4c3a9bf53735b2e1"
  version "1.0.0"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-bst-light-v1.0.0"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8ba067e83f8ca5721f90019aa6de165e46298268afba7fd481f33b6df39c5d17"
  end

  livecheck do
    skip "development tool, manually versioned"
  end

  # Unlike binary-sign-tool from ohos-sdk, self-sign preserves the ELF structure
  # of Bun-built binaries. binary-sign-tool can corrupt ELF section layout,
  # preventing Bun's runtime from finding embedded resources.
  depends_on "ohos-sdk" => :build

  def install
    system "clang", "self-sign.c", "-o", "self-sign"
    bin.install "self-sign"
  end

  test do
    assert_path_exists bin/"self-sign"
  end
end
