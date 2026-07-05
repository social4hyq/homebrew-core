class SshAudit < Formula
  include Language::Python::Virtualenv

  desc "SSH server & client auditing"
  homepage "https://github.com/jtesta/ssh-audit"
  url "https://files.pythonhosted.org/packages/b4/95/0dc036428ef8d76e2c812cbec9e69c2020230da32ea0e699908735894a2f/ssh_audit-3.9.0.tar.gz"
  sha256 "f1225d0364b3cb61c7dfb1f5065a6958dbb814d98b2c1dd2a779ba2cdef41f61"
  license "MIT"
  head "https://github.com/jtesta/ssh-audit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b4cdcd8197a944ab373a356070ac8761c56638122c6aa2b355b77a73a7befe0f"
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    output = shell_output("#{bin}/ssh-audit -nt 0 ssh.github.com", 1)
    assert_match "[exception] cannot connect to ssh.github.com port 22", output

    assert_match "ssh-audit v#{version}", shell_output("#{bin}/ssh-audit -h")
  end
end
