class Mdformat < Formula
  include Language::Python::Virtualenv

  desc "CommonMark compliant Markdown formatter"
  homepage "https://mdformat.readthedocs.io/en/stable/"
  url "https://files.pythonhosted.org/packages/3f/05/32b5e14b192b0a8a309f32232c580aefedd9d06017cb8fe8fce34bec654c/mdformat-1.0.0.tar.gz"
  sha256 "4954045fcae797c29f86d4ad879e43bb151fa55dbaf74ac6eaeacf1d45bb3928"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "184115e14f6df117f510de645d825946cd78c8acdb02775651bc3ea8542692e8"
  end

  depends_on "python@3.14"

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/5b/f5/4ec618ed16cc4f8fb3b701563655a69816155e79e24a17b651541804721d/markdown_it_py-4.0.0.tar.gz"
    sha256 "cb0a2b4aa34f932c007117b194e945bd74e0ec24133ceb5bac59009cda1cb9f3"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/d6/54/cfe61301667036ec958cb99bd3efefba235e65cdeb9c84d24a8293ba1d90/mdurl-0.1.2.tar.gz"
    sha256 "bb413d29f5eea38f31dd4754dd7377d4465116fb207585f97bf925588687c1ba"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"test.md").write("# mdformat")
    system bin/"mdformat", testpath
  end
end
