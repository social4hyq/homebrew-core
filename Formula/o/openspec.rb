class Openspec < Formula
  desc "Spec-driven development (SDD) for AI coding assistants"
  homepage "https://openspec.dev/"
  url "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-1.11.0.tgz"
  sha256 "84820b173b57204bd7582a47ddae65e85fd492724172acc8e434e97ea1c05c3f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4e7f22f89c6c2af93a8e91fa523e1f69b0e55ccf8d4c9cbd427c862752299e49"
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
