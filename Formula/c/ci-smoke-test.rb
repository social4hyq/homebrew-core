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

  def install
    (bin/"ci-smoke-test").write "#!/bin/sh\necho ok\n"
    chmod 0755, bin/"ci-smoke-test"
  end

  test do
    assert_match "ok", shell_output(bin/"ci-smoke-test")
  end
end
