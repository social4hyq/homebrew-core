class Openspec < Formula
  desc "Spec-driven development (SDD) for AI coding assistants"
  homepage "https://openspec.dev/"
  url "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-1.13.0.tgz"
  sha256 "f3c129f3f1e3aece105a4c1798301c7b6faeacec8a30eec8def63787e4d59ace"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22f080a88efd459419130a1e5257c77af7a162bdd8a193adb0f25372ef2a4167"
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
