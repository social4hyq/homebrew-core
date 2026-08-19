class ActionsUp < Formula
  desc "Tool to update GitHub Actions to latest versions with SHA pinning"
  homepage "https://github.com/azat-io/actions-up"
  url "https://registry.npmjs.org/actions-up/-/actions-up-1.17.1.tgz"
  sha256 "211923458c417416df951da425f7696c835faf38cf684e1a02eb4a606c101998"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8d907edccb83306f5bd52cf2d3b4e72ea435aab428aeff61110ade4c6129ff99"
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
