class Jsbeautifier < Formula
  include Language::Python::Virtualenv

  desc "JavaScript unobfuscator and beautifier"
  homepage "https://beautifier.io"
  url "https://files.pythonhosted.org/packages/48/a4/6283089b46c2bd895f5c4b223456167ea859ce54fed01f4c1ee4e8a8ed20/jsbeautifier-2.0.1.tar.gz"
  sha256 "45603b2097410feee8d3a6ef8ad5a8e0a0e89f347331888a97e46f332ce8d953"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca047f2e14db98d58bda517489b561139f2b1879276ac9c03d0cb3e5ff407abe"
  end

  depends_on "python@3.14"

  conflicts_with "js-beautify", because: "both install `js-beautify` binaries"

  resource "editorconfig" do
    url "https://files.pythonhosted.org/packages/88/3a/a61d9a1f319a186b05d14df17daea42fcddea63c213bcd61a929fb3a6796/editorconfig-0.17.1.tar.gz"
    sha256 "23c08b00e8e08cc3adcddb825251c497478df1dada6aefeb01e626ad37303745"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    javascript = "if ('this_is'==/an_example/){of_beautifier();}else{var a=b?(c%d):e[f];}"
    assert_equal <<~EOS.chomp, pipe_output(bin/"js-beautify", javascript)
      if ('this_is' == /an_example/) {
          of_beautifier();
      } else {
          var a = b ? (c % d) : e[f];
      }
    EOS
  end
end
