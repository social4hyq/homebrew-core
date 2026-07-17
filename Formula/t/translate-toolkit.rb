class TranslateToolkit < Formula
  include Language::Python::Virtualenv

  desc "Toolkit for localization engineers"
  homepage "https://toolkit.translatehouse.org/"
  url "https://files.pythonhosted.org/packages/12/9b/b5a1ad047af188983eac294cabad8492d0ffeca48028f7fa37aa18574e11/translate_toolkit-3.19.15.tar.gz"
  sha256 "d4762323eb27dcf344de4ca5050ae67a9fa84b06b6b7f0f486c12970a363c96a"
  license "GPL-2.0-or-later"
  head "https://github.com/translate/translate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0cdc39e1ebc6b9ab2ad60ff3ee93d5419e22c39a959cb5208e2b11517cc5a7a2"
  end

  depends_on "rust" => :build # for `unicode_segmentation_py`
  depends_on "python@3.14"

  uses_from_macos "libxml2", since: :ventura
  uses_from_macos "libxslt"

  resource "lxml" do
    url "https://files.pythonhosted.org/packages/05/3b/aab6728cae887456f409b4d75e8a01856e4f04bd510de38052a47768b680/lxml-6.1.1.tar.gz"
    sha256 "ba96ae44888e0185281e937633a743ea90d5a196c6000f82565ebb0580012d40"
  end

  resource "unicode-segmentation-rs" do
    url "https://files.pythonhosted.org/packages/4e/71/52f1a87120d92eafbd56c98e0d7abeb10d097bbd3dfb697bd8bc1dcd9070/unicode_segmentation_rs-0.3.0.tar.gz"
    sha256 "6178f1097f3b1bf8098b43e35daea302c994a738f786b807890ef6ace21abf94"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    test_file = testpath/"test.po"
    touch test_file
    assert_match "Processing file : #{test_file}", shell_output("#{bin}/pocount --no-color #{test_file}")

    assert_match version.to_s, shell_output("#{bin}/pretranslate --version")
    assert_match version.to_s, shell_output("#{bin}/podebug --version")
  end
end
