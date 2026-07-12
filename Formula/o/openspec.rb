class Openspec < Formula
  desc "Spec-driven development (SDD) for AI coding assistants"
  homepage "https://openspec.dev/"
  url "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-1.6.0.tgz"
  sha256 "a80477767e98a62e956464ad09a44b28cacc4fcbfde23765f7b4ba598ee13859"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "231d2b4bf5399c95233c32430252ad14d3dd33f695ac1dee3de3b4d5f2e39b3e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
    generate_completions_from_executable(bin/"openspec", "completion", "generate")
  end

  test do
    system bin/"openspec", "init", "--tools", "none"
    assert_path_exists testpath/"openspec/changes"
    assert_path_exists testpath/"openspec/specs"
  end
end
