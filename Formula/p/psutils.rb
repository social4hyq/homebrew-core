class Psutils < Formula
  include Language::Python::Virtualenv

  desc "Utilities for manipulating PostScript documents"
  homepage "https://github.com/rrthomas/psutils"
  url "https://files.pythonhosted.org/packages/a0/6b/735ab226ab8e2ee6b99182312c7346a2e4bd3e825cfdf127f22ce75e853f/psutils-3.3.17.tar.gz"
  sha256 "3ff76cc9f9fb535ec553d1591de56d6dbaa0d9f4df86778f6a49731ebd764cdf"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "657b49d9b5f48cf6e6b901bf3527ba2a6abefcea61d1d3cf4206f9b3effc2307"
  end

  depends_on "libpaper"
  depends_on "python@3.14"

  resource "puremagic" do
    url "https://files.pythonhosted.org/packages/24/74/ce5987ab9b8aec4ced06e2723ebb604205c9eb58abdad91453da93166380/puremagic-2.2.0.tar.gz"
    sha256 "eb4bddf07c177c4b434554b92165b67449f5a51e152b976202d6254498810eef"
  end

  resource "pypdf" do
    url "https://files.pythonhosted.org/packages/c2/c3/9fa0666f280552bd3833562d985b785fce1ddb3804937edd2fd6a3f2bdb3/pypdf-6.18.0.tar.gz"
    sha256 "ae58b7d93c22c169ffb02c3b06321c45c4f223b4916536568adb57d789d95d01"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    resource "homebrew-test-ps" do
      url "https://raw.githubusercontent.com/rrthomas/psutils/e00061c21e114d80fbd5073a4509164f3799cc24/tests/test-files/psbook/3/expected.ps"
      sha256 "bf3f1b708c3e6a70d0f28af55b3b511d2528b98c2a1537674439565cecf0aed6"
    end
    resource("homebrew-test-ps").stage testpath

    expected_psbook_output = "[4] [1] [2] [3] \nWrote 4 pages\n"
    assert_equal expected_psbook_output, shell_output("#{bin}/psbook expected.ps book.ps 2>&1")

    expected_psnup_output = "[1,2] [3,4] \nWrote 2 pages\n"
    assert_equal expected_psnup_output, shell_output("#{bin}/psnup -2 expected.ps nup.ps 2>&1")

    expected_psselect_output = "[1] \nWrote 1 pages\n"
    assert_equal expected_psselect_output, shell_output("#{bin}/psselect -p1 expected.ps test2.ps 2>&1")
  end
end
