class ActionsUp < Formula
  desc "Tool to update GitHub Actions to latest versions with SHA pinning"
  homepage "https://github.com/azat-io/actions-up"
  url "https://registry.npmjs.org/actions-up/-/actions-up-1.20.0.tgz"
  sha256 "43be99d049d9c2f59e78fe4d745c2b0dc58da585d90d7a7fb891b6f4171652d0"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e77dff389245ee0e1af18fbc8d0d574ae62aee2383cc9255ba61dd5e4461245"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/actions-up --version")

    test_file = testpath/".github/workflows/action.yml"
    test_file.write <<~YAML
      name: CI

      on: push

      jobs:
        build:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v3
            - run: npm install && npm test
    YAML

    assert_match "Updates applied successfully!", shell_output("#{bin}/actions-up --yes")

    assert_match(%r{.*?actions/checkout@[a-f0-9]{40}}, test_file.read)
  end
end
