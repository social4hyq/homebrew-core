class Dynaconf < Formula
  include Language::Python::Virtualenv

  desc "Configuration Management for Python"
  homepage "https://www.dynaconf.com/"
  url "https://files.pythonhosted.org/packages/71/e4/723ba469856bb493c948985e5bd562c8a65f2b93e70c896e9764ab76de00/dynaconf-3.3.5.tar.gz"
  sha256 "a08f6ab44025034ef3c9f86b32548ab01efd4039094a74bd9f028a43c63d016f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ca9ca39b212ddc57f5ce13fe0cee9da53047cefb6b2af16c91b1550dfb6d4c4"
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
