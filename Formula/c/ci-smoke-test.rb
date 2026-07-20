class CiSmokeTest < Formula
  desc "No-op formula to smoke-test the pr-validate/publish-on-merge CI"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo, same pattern as dlopen-sign-shim/inject-runpath:
  # install() never reads from the checkout, this only satisfies Homebrew's
  # url/resource requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "463bcbe3c911047cbf34185ead1d8c0f60abf3a4"
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "CI smoke-test formula, no upstream"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ci-smoke-test-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "596e260ea9b9f681f50952d25ff6ef717a490e7f2b2ed63bd634c5bd5dbea37a"
  end

  def install
    (bin/"ci-smoke-test").write "#!/bin/sh\necho ok\n"
    chmod 0755, bin/"ci-smoke-test"
  end

  test do
    assert_match "ok", shell_output(bin/"ci-smoke-test")
  end
end
