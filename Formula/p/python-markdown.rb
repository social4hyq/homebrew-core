class PythonMarkdown < Formula
  include Language::Python::Virtualenv

  desc "Python implementation of Markdown"
  homepage "https://python-markdown.github.io"
  url "https://files.pythonhosted.org/packages/29/6f/da4c6aea59b3001f2e8c0ec7497475aadaf3b021c10cab5b2858f0f32b26/markdown-3.10.3.tar.gz"
  sha256 "3589362618f743188b4d955b874402bc814f4f83f544dc207719f4baa7d9c45f"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/Python-Markdown/markdown.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bd041922061721d54925e19ded8fd5ac8182d54399f011b5bddf6248c7c01e4c"
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"test.md").write("# Hello World!")
    assert_equal "<h1>Hello World!</h1>", shell_output("#{bin}/markdown_py test.md").strip
  end
end
