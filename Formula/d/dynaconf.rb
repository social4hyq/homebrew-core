class Dynaconf < Formula
  include Language::Python::Virtualenv

  desc "Configuration Management for Python"
  homepage "https://www.dynaconf.com/"
  url "https://files.pythonhosted.org/packages/2e/fa/351d165f6f9fe493a92a2e155f3097a4379dbe23e731b68543ce9988ee19/dynaconf-3.3.2.tar.gz"
  sha256 "3b50232b774142702c3d4623633bcd76bb9951abf8567b7f1340d73a30a80899"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdbf9c35dcccfa525769d176afc1d776a8e2b760f983a14da04338b8a42dc4f9"
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
