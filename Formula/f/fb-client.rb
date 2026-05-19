class FbClient < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Shell-script client for https://paste.xinu.at"
  homepage "https://paste.xinu.at"
  url "https://paste.xinu.at/data/client/fb-2.4.0.tar.gz"
  sha256 "a3dd5580c7ba459c18f2d2ac39614422fd9c0dccb4545dbd683c77104062af39"
  license "GPL-3.0-only"

  livecheck do
    url :homepage
    regex(%r{Latest release:.*?href=.*?/fb[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c21dde35aac37407df8ef15116a60bc7accd460f44384d9bddf76f35506b311"
  end

  depends_on "curl"
  depends_on "openssl@3"
  depends_on "python@3.14"

  conflicts_with "spotbugs", because: "both install a `fb` binary"

  pypi_packages package_name:   "",
                extra_packages: ["pycurl", "pyxdg"]

  resource "pycurl" do
    url "https://files.pythonhosted.org/packages/95/23/cc07b16591af8ca373494d29aafc8df13e547077579e6779bb865a3f5a7f/pycurl-7.46.0.tar.gz"
    sha256 "422ed7005b98768fe60fe6b6cb8bb6a4e1fc18b5433402e8fbdaba91811c4604"
  end

  resource "pyxdg" do
    url "https://files.pythonhosted.org/packages/b0/25/7998cd2dec731acbd438fbf91bc619603fc5188de0a9a17699a781840452/pyxdg-0.28.tar.gz"
    sha256 "3267bb3074e934df202af2ee0868575484108581e6f3cb006af1da35395e88b4"
  end

  def install
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources

    rw_info = python_shebang_rewrite_info(libexec/"bin/python")
    rewrite_shebang rw_info, "fb"

    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    system bin/"fb", "-h"
  end
end
