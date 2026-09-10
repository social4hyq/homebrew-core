class TranslateToolkit < Formula
  include Language::Python::Virtualenv

  desc "Toolkit for localization engineers"
  homepage "https://toolkit.translatehouse.org/"
  url "https://files.pythonhosted.org/packages/a3/65/72c1346001fc92f3b2f69d126918f5f7ef96c9ad439256b05a614ca7df1c/translate_toolkit-3.19.19.tar.gz"
  sha256 "f8099801886845f46f63457ceb312284421b76711e76e9053b9c1ae50b2faf16"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/translate/translate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c17cb1a1b263419665957486f55b7d99593c029317471b73a7ea0faf2e2391a9"
  end

  depends_on "rust" => :build # for `unicode_segmentation_py`
  depends_on "python@3.14"

  uses_from_macos "libxml2", since: :ventura
  uses_from_macos "libxslt"

  resource "lxml" do
    url "https://files.pythonhosted.org/packages/23/ad/28ecd7cb894d172f3c9c80a075eeeb2017ac62e3632cee05a5f9493547eb/lxml-6.1.3.tar.gz"
    sha256 "45222d94ddd511536f3b2f7d9deae3b2339b4ce0f075f1ca25703b07cad9dd21"
  end

  resource "unicode-segmentation-rs" do
    url "https://files.pythonhosted.org/packages/0b/02/e5804acc54945ecf29a280f5f173db61c019166bfe3adeee386f4c135f17/unicode_segmentation_rs-0.3.3.tar.gz"
    sha256 "d6625b2d3435ca814c9dd6590d39ae58ebeb8a4891eecb81446ad8b3e917f39b"
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
