class Dynaconf < Formula
  include Language::Python::Virtualenv

  desc "Configuration Management for Python"
  homepage "https://www.dynaconf.com/"
  url "https://files.pythonhosted.org/packages/57/0e/05927cf459e73f8bf9a9277cbea6f2d5b7db8a5cc9dc1e20e7a5fbac1b90/dynaconf-3.2.13.tar.gz"
  sha256 "d79e0189d97b3f226b8ebb1717e2ce05d1a05cdf6ea05de66d24625fdb5a0cbd"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b43da10f8bd7614c42f60c8e5998014f3b32f5209e451e5c9e31f28e888e222d"
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
