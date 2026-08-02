class TranslateToolkit < Formula
  include Language::Python::Virtualenv

  desc "Toolkit for localization engineers"
  homepage "https://toolkit.translatehouse.org/"
  url "https://files.pythonhosted.org/packages/f8/e0/c8f825a4066aafee220036e0d32a378f0588a0128b147c167c62931de491/translate_toolkit-3.19.17.tar.gz"
  sha256 "1381542791a0759a7c7f2ff7157f354f0c4bfab66a6d97834d3f631c6f659a04"
  license "GPL-2.0-or-later"
  head "https://github.com/translate/translate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f14d5cd9106150656b609f50226cd40c94b1fc7017fbb98a4f4da28c0ce367cf"
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
    url "https://files.pythonhosted.org/packages/27/23/2b8888406ad5d178edbdb6efcc55740b7c307077800a705632771d34031a/unicode_segmentation_rs-0.3.1.tar.gz"
    sha256 "f7e852f8bf3dfa9073aec148d13d239fa2597b804a3e6ff51050beb59bb79a6e"
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
