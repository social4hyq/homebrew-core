class CiSmokeTest2 < Formula
  desc "No-op formula to smoke-test lint-commits/upstream-diff/bottle-gc"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo, same pattern as dlopen-sign-shim/inject-runpath:
  # install() never reads from the checkout, this only satisfies Homebrew's
  # url/resource requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "8d3eef4e89cd872df39e3c263593a16259a36df1"
  version "0.2.0"
  license "MIT"

  livecheck do
    skip "CI smoke-test formula, no upstream"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ci-smoke-test-2-v0.2.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a38eee69d38780059c7842de2b618f7a9c8866f7edfe55c0584fa8b2af64a03"
  end

  def install
    (bin/"ci-smoke-test-2").write "#!/bin/sh\necho ok\n"
    chmod 0755, bin/"ci-smoke-test-2"
  end

  test do
    assert_match "ok", shell_output(bin/"ci-smoke-test-2")
  end
end
