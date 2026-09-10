class Scons < Formula
  include Language::Python::Virtualenv

  desc "Substitute for classic 'make' tool with autoconf/automake functionality"
  homepage "https://www.scons.org/"
  url "https://files.pythonhosted.org/packages/42/b9/b7a5c88f348a0c34594d88100872c55fa1cae863ccb222c1c438341b5503/scons-4.11.1.tar.gz"
  sha256 "4210d1a80a62e986029208117991b6347ccaaaab37b67463a3ff31ee065dc487"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "323856d799452b6df63a91b6ceefaccdbf1800bcdca30c5cf50b11608d7602eb"
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
