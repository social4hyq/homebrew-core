class CiSmokeTest2 < Formula
  desc "No-op formula to smoke-test lint-commits/upstream-diff/bottle-gc"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo, same pattern as dlopen-sign-shim/inject-runpath:
  # install() never reads from the checkout, this only satisfies Homebrew's
  # url/resource requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "d85ed77f4c4523bdc8d4fd5d23c3ac3ff41f2459"
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "CI smoke-test formula, no upstream"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ci-smoke-test-2-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d3743b23277c7219c85db977e0fd6eb5ee8a4d91852b19a4d0a9259b3514623"
  end

  def install
    (bin/"ci-smoke-test-2").write "#!/bin/sh\necho ok\n"
    chmod 0755, bin/"ci-smoke-test-2"
  end

  test do
    assert_match "ok", shell_output(bin/"ci-smoke-test-2")
  end
end
