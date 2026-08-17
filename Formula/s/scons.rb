class Scons < Formula
  include Language::Python::Virtualenv

  desc "Substitute for classic 'make' tool with autoconf/automake functionality"
  homepage "https://www.scons.org/"
  url "https://files.pythonhosted.org/packages/dd/82/3c4e089ac8df2eaee8a7f14e489b2a76f94f4c1d8defa4e46c8ad15cae86/scons-4.11.0.tar.gz"
  sha256 "5ba48f9e2eb6b9178cabdc9893792418e6970c84f43f4b027e4468e20616a89c"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2140684b205b8b0b97e4e6cff34cbe1c67a1f1284da0d3011302e864450f174a"
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      int main()
      {
        printf("Homebrew");
        return 0;
      }
    C
    (testpath/"SConstruct").write "Program('test.c')"
    system bin/"scons"
    assert_equal "Homebrew", shell_output("#{testpath}/test")
  end
end
