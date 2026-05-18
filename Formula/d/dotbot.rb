class Dotbot < Formula
  include Language::Python::Virtualenv

  desc "Tool that bootstraps your dotfiles"
  homepage "https://github.com/anishathalye/dotbot"
  url "https://files.pythonhosted.org/packages/ce/99/905f34404698d54de29fbc1dcbb9fdc4b1bbd4b5b30207750ff5ad5b5c69/dotbot-1.24.1.tar.gz"
  sha256 "83def50fa1625530066f105b88c2dc1c61e27536433488a12324eb0b55a14730"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f17f86b0e2ad8bbbae722419c4f7a68f940a575684ba793146f08a76cc897d11"
  end

  depends_on "libyaml"
  depends_on "python@3.14"

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"install.conf.yaml").write <<~YAML
      - create:
        - brew
        - .brew/test
    YAML

    output = shell_output("#{bin}/dotbot --verbose -c #{testpath}/install.conf.yaml")
    assert_match "All tasks executed successfully", output
    assert_path_exists testpath/"brew"
    assert_path_exists testpath/".brew/test"
  end
end
