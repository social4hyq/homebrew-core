class Dynaconf < Formula
  include Language::Python::Virtualenv

  desc "Configuration Management for Python"
  homepage "https://www.dynaconf.com/"
  url "https://files.pythonhosted.org/packages/5c/c2/5c8b5f4003bfd5a4666a324a60e08e8bb1bd5d2966159de8dbfdd61a8ca7/dynaconf-3.3.4.tar.gz"
  sha256 "f387bf8dabb85e28a5a79f8a0cac81e5d4da7f37c055dc93d34ed6decb4eff49"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c2eae80fecf56fef33be0f85e0e052946e297068cf67393edc4071ece505741"
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    system bin/"dynaconf", "init"
    assert_path_exists testpath/"settings.toml"
    assert_match "from dynaconf import Dynaconf", (testpath/"config.py").read
  end
end
