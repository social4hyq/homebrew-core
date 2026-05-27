class Unoconv < Formula
  include Language::Python::Virtualenv

  desc "Convert between any document format supported by OpenOffice"
  homepage "https://github.com/unoconv/unoconv"
  url "https://files.pythonhosted.org/packages/ab/40/b4cab1140087f3f07b2f6d7cb9ca1c14b9bdbb525d2d83a3b29c924fe9ae/unoconv-0.9.0.tar.gz"
  sha256 "308ebfd98e67d898834876348b27caf41470cd853fbe2681cc7dacd8fd5e6031"
  license "GPL-2.0-only"
  revision 4
  head "https://github.com/unoconv/unoconv.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3737ff4576d425f25e687a6a45d9d3ff2750b44e7273c679063d10a7bc5c7bde"
  end

  deprecate! date: "2025-04-27", because: :repo_archived, replacement_formula: "unoserver"
  disable! date: "2026-04-27", because: :repo_archived, replacement_formula: "unoserver"

  depends_on "python@3.14"

  pypi_packages extra_packages: "setuptools"

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/18/5d/3bf57dcd21979b887f014ea83c24ae194cfcd12b9e0fda66b957c69d1fca/setuptools-80.9.0.tar.gz"
    sha256 "f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c"
  end

  def install
    virtualenv_install_with_resources
    man1.install "doc/unoconv.1"
  end

  def caveats
    <<~EOS
      In order to use unoconv, a copy of LibreOffice between versions 3.6.0.1 - 4.3.x must be installed.
    EOS
  end

  test do
    assert_match "office installation", pipe_output("#{bin}/unoconv 2>&1")
  end
end
