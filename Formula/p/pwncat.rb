class Pwncat < Formula
  include Language::Python::Virtualenv

  desc "Netcat with FW/IDS/IPS evasion, self-inject-, bind- and reverse shell"
  homepage "https://pwncat.org"
  url "https://files.pythonhosted.org/packages/c9/ce/51f7b53a8ee3b4afe4350577ee92f416f32b9b166f0d84b480fec1717a42/pwncat-0.1.2.tar.gz"
  sha256 "c7f879df3a58bae153b730848a88b0e324c8b7f8c6daa146e67cf45a6c736088"
  license "MIT"
  head "https://github.com/cytopia/pwncat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "041d46d4ccef1441e6243b0c2bf3015643db1e3095511452ec4b550eb1eb7a07"
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    system "echo HEAD  | #{bin}/pwncat www.google.com 80 | grep ^HTTP"
  end
end
