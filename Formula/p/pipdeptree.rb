class Pipdeptree < Formula
  include Language::Python::Virtualenv

  desc "CLI to display dependency tree of the installed Python packages"
  homepage "https://github.com/tox-dev/pipdeptree"
  url "https://files.pythonhosted.org/packages/a1/68/34d47650e9ad35b7f5beb4666c7a0e79fc2589a839116aadc2e4ab16d2bb/pipdeptree-4.2.3.tar.gz"
  sha256 "f95876e4feddadeaffaeb579990bf94bd6035e7dc87569f5cba2ac6669ea3ebe"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac32aca3a25c752f869daaa7a614ee44c3f9990861fe6d0ab2d143a99dc6637e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "rust" => :build
  depends_on "python@3.14"

  pypi_packages exclude_packages: "meson",
                extra_packages:   "meson-python"

  resource "build" do
    url "https://files.pythonhosted.org/packages/4d/b7/1db48a9ce2984842c8c886432ec8a2719613322e868a966ba82a28862f25/build-1.6.0.tar.gz"
    sha256 "bd2c8afc603e7a2e0ce70e2ea85f0a6d02043bafbd307f5bada0f98669eca5af"
  end

  resource "installer" do
    url "https://files.pythonhosted.org/packages/06/fe/b9f481cf0cc867958a21338baa900357b7b7d86cac9b025948049d77923c/installer-1.0.1.tar.gz"
    sha256 "052c7fc3721d54c696e2dea019be67539d7b144e924f559f54beb3121831c364"
  end

  resource "meson-python" do
    url "https://files.pythonhosted.org/packages/8b/f0/d794d7ed8a843a8a8947768f3b329d1e8601222dc95d930f4a5f9706cd6c/meson_python-0.20.0.tar.gz"
    sha256 "6d9726ae6cd37e22f210c74b364b30180a68c20442e97ff09f3c566a414af738"
  end

  resource "nab-index" do
    url "https://files.pythonhosted.org/packages/31/37/31463c5c5ddf949934ef965393dde6a923b3f75ed02e122d93862217d1c9/nab_index-0.0.16.tar.gz"
    sha256 "4d11be68083431cc941fb5bd01d52557e47b0aa2405adee79fad36bc36b30cbd"
  end

  resource "nab-markersets" do
    url "https://files.pythonhosted.org/packages/bb/5b/d4e28f7deb79664930552fe13a2cd6745055b43e8e97d9c897c042349cbf/nab_markersets-0.0.16.tar.gz"
    sha256 "5d4649567dcf03d565c5fba52afeddcdcf85818f1ce45279766c2db9fe25f5c8"
  end

  resource "nab-project" do
    url "https://files.pythonhosted.org/packages/c1/09/daaa422313ae401dddb50a6d141f840f10789cfd44449f2cd22ead1422d2/nab_project-0.0.16.tar.gz"
    sha256 "43b94bb0eb9925d2786ef0259dc719249d0fd5d5351e4a5cc5dbc4478e487adc"
  end

  resource "nab-provider" do
    url "https://files.pythonhosted.org/packages/8e/6b/07c94dc10289c62cf81120852e9847fb56897feaeb0edb861ea4e8d2902f/nab_provider-0.0.16.tar.gz"
    sha256 "de498dcd65015635755773c7cabfad857f2b99afdb7939b5f2836c1f1f0ca444"
  end

  resource "nab-resolver" do
    url "https://files.pythonhosted.org/packages/8a/ff/cef63ba1c7d47d9be040ae81f1bdae251dd906b7cd34b6fed616566deca7/nab_resolver-0.0.16.tar.gz"
    sha256 "540316b26d92ba891adcc0c54c0dec2d79f859a3cc4a416aabd36d5fc5278c3e"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/7d/fa/3944b40b07da9ce895c0e6303a5ab7d53da063554f534556b134a54d6093/packaging-26.3.tar.gz"
    sha256 "94edc256424af38762eb31306eed28beb9f0efc50a8837492c9d6fd6004aed79"
  end

  resource "pyproject-hooks" do
    url "https://files.pythonhosted.org/packages/e7/82/28175b2414effca1cdac8dc99f76d660e7a4fb0ceefa4b4ab8f5f6742925/pyproject_hooks-1.2.0.tar.gz"
    sha256 "1e859bd5c40fae9448642dd871adf459e5e2084186e8d2c2a79a824c970da1f8"
  end

  resource "pyproject-metadata" do
    url "https://files.pythonhosted.org/packages/4f/76/1cae539918a7b1746d624c2f01560b793c22cd8c081157505bb9bbf0e34d/pyproject_metadata-0.12.1.tar.gz"
    sha256 "8809a4df6fe08279b39a8890669506ed3158e0617855ac9aff098fcbe772ae4c"
  end

  resource "tomli" do
    url "https://files.pythonhosted.org/packages/22/de/48c59722572767841493b26183a0d1cc411d54fd759c5607c4590b6563a6/tomli-2.4.1.tar.gz"
    sha256 "7c7e1a961a0b2f2472c1ac5b69affa0ae1132c39adcb67aba98568702b9cc23f"
  end

  resource "tomli-w" do
    url "https://files.pythonhosted.org/packages/19/75/241269d1da26b624c0d5e110e8149093c759b7a286138f4efd61a60e75fe/tomli_w-1.2.0.tar.gz"
    sha256 "2dd14fac5a47c27be9cd4c976af5a12d87fb1f0b4512f81d69cce3b35ae25021"
  end

  resource "truststore" do
    url "https://files.pythonhosted.org/packages/53/a3/1585216310e344e8102c22482f6060c7a6ea0322b63e026372e6dcefcfd6/truststore-0.10.4.tar.gz"
    sha256 "9d91bd436463ad5e4ee4aba766628dd6cd7010cf3e2461756b3303710eebc301"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/53/0c/06f8b233b8fd13b9e5ee11424ef85419ba0d8ba0b3138bf360be2ff56953/urllib3-2.7.0.tar.gz"
    sha256 "231e0ec3b63ceb14667c67be60f2f2c40a518cb38b03af60abc813da26505f4c"
  end

  def install
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources.reject { |r| r.name == "meson-python" }
    # meson-python self-hosts via backend-path; without isolation it uses brew meson and ninja
    venv.pip_install resource("meson-python"), build_isolation: false
    venv.pip_install_and_link buildpath, build_isolation: false
  end

  test do
    assert_match "pipdeptree==#{version}", shell_output("#{bin}/pipdeptree --all")

    assert_empty shell_output("#{bin}/pipdeptree --user-only").strip

    assert_equal version.to_s, shell_output("#{bin}/pipdeptree --version").strip
  end
end
