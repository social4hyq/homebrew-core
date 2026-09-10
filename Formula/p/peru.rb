class Peru < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Dependency retriever for version control and archives"
  homepage "https://github.com/buildinspace/peru"
  url "https://files.pythonhosted.org/packages/46/93/97b31e2052b4308cbc413d85b6b6b08a3beeeac81996b070723418a0c24e/peru-1.3.5.tar.gz"
  sha256 "2cc1a0d09c5d4fc28dda5c4bf87b4110ee2107e9ce7fb6a38f8d6f60a91af745"
  license "MIT"
  revision 1
  head "https://github.com/buildinspace/peru.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08008a3117bafba3ea2900ab9a2a0c2f819d1bdf413402838bc55cbd8244aad3"
  end

  depends_on "libyaml"
  depends_on "python@3.14"

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    venv = virtualenv_install_with_resources

    # Fix executable plugins looking for Python outside the virtualenv
    rw_info = python_shebang_rewrite_info(venv.root/"bin/python")
    rewrite_shebang rw_info, *venv.site_packages.glob("peru/resources/plugins/**/*.py")
  end

  test do
    (testpath/"peru.yaml").write <<~YAML
      imports:
        peru: peru
      git module peru:
        url: https://github.com/buildinspace/peru.git
    YAML

    system bin/"peru", "sync"
    assert_path_exists testpath/".peru"
    assert_path_exists testpath/"peru"
  end
end
