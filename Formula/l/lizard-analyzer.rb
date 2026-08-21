class LizardAnalyzer < Formula
  include Language::Python::Virtualenv

  desc "Extensible Cyclomatic Complexity Analyzer"
  homepage "https://github.com/terryyin/lizard"
  url "https://files.pythonhosted.org/packages/a5/c9/97837b967a1a6bb64acb0e1738e19a154393ae1a9a448b9958176be5b10a/lizard-1.24.0.tar.gz"
  sha256 "2e88a7af9d23a98d3f4a30767134361bd4b7dde02c410209c6c72732a43bbb65"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "083ee99e15204a361a917b767d1a697aafc5e66bb3106945a19027571f58b3d9"
  end

  depends_on "python@3.14"

  conflicts_with "lizard", because: "both install `lizard` binaries"

  resource "pathspec" do
    url "https://files.pythonhosted.org/packages/5a/82/42f767fc1c1143d6fd36efb827202a2d997a375e160a71eb2888a925aac1/pathspec-1.1.1.tar.gz"
    sha256 "17db5ecd524104a120e173814c90367a96a98d07c45b2e10c2f3919fff91bf5a"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/49/2e/ced460408999b33da6b31b0021b0f37d329e202d4169aeb164493778f25b/pygments-2.21.0.tar.gz"
    sha256 "610ca751c9bc2492b38eb9a38a7fbc93edbbb2d7182edaf34e66ae493dee5c8c"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"test.swift").write <<~SWIFT
      let base = 2
      let exponent_inner = 3
      let exponent_outer = 4
      var answer = 1

      for _ in 1...exponent_outer {
        for _ in 1...exponent_inner {
          answer *= base
        }
      }
    SWIFT

    assert_match "1 file analyzed.", shell_output("#{bin}/lizard -l swift #{testpath}/test.swift")
  end
end
