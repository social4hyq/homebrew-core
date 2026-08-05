class Pipenv < Formula
  include Language::Python::Virtualenv

  desc "Python dependency management tool"
  homepage "https://github.com/pypa/pipenv"
  url "https://files.pythonhosted.org/packages/e8/af/aebabe333f35f71220a860fb1f6de5ccd7942c4029ae09fce7aada5f9644/pipenv-2026.7.1.tar.gz"
  sha256 "29b9450d52eff3570b28f35d30586cccca68e89a579b92ce4f0b6b59aef30214"
  license "MIT"
  head "https://github.com/pypa/pipenv.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7082df4eea24c7c0f915aaaf7de2919f3deabd5d8c94cbecc93a93a52066ca76"
  end

  depends_on "certifi" => :no_linkage
  depends_on "python@3.14"

  pypi_packages package_name:     "pipenv[completion]",
                exclude_packages: "certifi"

  def python3
    "python3.14"
  end

  resource "argcomplete" do
    url "https://files.pythonhosted.org/packages/d1/40/8a867253c9b8afa296ac22e426a157eebbe41dcac66f7f50bbbef931afed/argcomplete-3.7.1.tar.gz"
    sha256 "6926a3a70ae70dce1f3dfb5cf1fc984278cd163e78ec18ad2ed7fa4fabd8f281"
  end

  resource "distlib" do
    url "https://files.pythonhosted.org/packages/c9/02/bd72be9134d25ed783ecbbc38a539ffaefbf90c78418c7fb7229600dbac7/distlib-0.4.3.tar.gz"
    sha256 "f152097224a0ae24be5a0f6bae1b9359af82133bce63f98a95f86cae1aede9ed"
  end

  resource "filelock" do
    url "https://files.pythonhosted.org/packages/f6/57/3ba6e6cb097f85b855b00163d169f35365f44277df044dcf96d55b8f62a3/filelock-3.32.2.tar.gz"
    sha256 "c33351e1f49cae33414acbc6d56784e6ecee82514ec90795da1161fc4836b5b8"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/7d/fa/3944b40b07da9ce895c0e6303a5ab7d53da063554f534556b134a54d6093/packaging-26.3.tar.gz"
    sha256 "94edc256424af38762eb31306eed28beb9f0efc50a8837492c9d6fd6004aed79"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/78/9b/560e4be8e26f6fd133a03630a8df0c663b9e8d61b4ade152b72005aec83b/platformdirs-4.11.0.tar.gz"
    sha256 "0555d18370482847566ffabcaa53ad7c6c1c29f195989ae1ed634a05f76ea1e0"
  end

  resource "python-discovery" do
    url "https://files.pythonhosted.org/packages/04/b7/1581a8103855c43567776aa34135e5ec3c597346c23bfd10c7eb5e0b10a4/python_discovery-1.5.1.tar.gz"
    sha256 "e2ea8b884cd1701f386eda8cf327b87743f1dc21b7f784470799537d95635384"
  end

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/34/26/f5d29e25ffdb535afef2d35cdb55b325298f96debd670da4c325e08d70f4/setuptools-83.0.0.tar.gz"
    sha256 "025bccbbf0fa05b6192bc64ae1e7b16e001fd6d6d4d5de03c97b1c1ade523bef"
  end

  resource "virtualenv" do
    url "https://files.pythonhosted.org/packages/ea/fa/18004e5cb15541ad2a68ff219c755233b012b12d4ec8663d06a258082bec/virtualenv-21.7.1.tar.gz"
    sha256 "d0dbfaa5483487baea28d7210ef8d24c9d1bd0f10f449eeb215568825a9b334e"
  end

  def install
    venv = virtualenv_install_with_resources

    generate_completions_from_executable(libexec/"bin/register-python-argcomplete", "pipenv", "--shell")

    # Build an `:all` bottle by replacing comments
    file = venv.site_packages.glob("argcomplete-*.dist-info/METADATA")
    inreplace file, "/opt/homebrew/bin/bash", "$HOMEBREW_PREFIX/bin/bash"
  end

  test do
    ENV["LC_ALL"] = "en_US.UTF-8"
    system bin/"pipenv", "--python", which(python3)
    system bin/"pipenv", "install", "requests"
    system bin/"pipenv", "install", "boto3"
    assert_path_exists testpath/"Pipfile"
    assert_path_exists testpath/"Pipfile.lock"
    assert_match "requests", (testpath/"Pipfile").read
    assert_match "boto3", (testpath/"Pipfile").read
  end
end
