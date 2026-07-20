class CiSmokeTest < Formula
  desc "No-op formula to smoke-test the pr-validate/publish-on-merge CI"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo, same pattern as dlopen-sign-shim/inject-runpath:
  # install() never reads from the checkout, this only satisfies Homebrew's
  # url/resource requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "faf0f1126a64ba49985f33be9f8e16214c8360c1"
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "CI smoke-test formula, no upstream"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ci-smoke-test-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa112ace753d2b9f80ddcc9e0255a8941a4473b71d4ae080e2666ead1840f1c8"
  end

  def install
    (bin/"ci-smoke-test").write "#!/bin/sh\necho ok\n"
    chmod 0755, bin/"ci-smoke-test"
  end

  test do
    assert_match "ok", shell_output(bin/"ci-smoke-test")
  end
end
