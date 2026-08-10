class ActionsUp < Formula
  desc "Tool to update GitHub Actions to latest versions with SHA pinning"
  homepage "https://github.com/azat-io/actions-up"
  url "https://registry.npmjs.org/actions-up/-/actions-up-1.17.0.tgz"
  sha256 "68debe4ee51dc3230f7d9865daaa28cf7da3ca2db8e165d3d7bf6eec37f54994"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "426235ab0ef6806e1d1d9ae877460d1d5809a6d21d9710e950261157ede39ac7"
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
