class Urlscan < Formula
  include Language::Python::Virtualenv

  desc "View/select the URLs in an email message or file"
  homepage "https://github.com/firecat53/urlscan"
  url "https://files.pythonhosted.org/packages/88/96/10143ccf034ce03a92e299530d877862c3db59de4dc1fecbf5dc6c73960e/urlscan-1.0.9.tar.gz"
  sha256 "067087895077762807ff028ed332e4e1ab6e1a7c249188dc846f6d160afba7ff"
  license "GPL-2.0-or-later"
  head "https://github.com/firecat53/urlscan.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "196390dbfa164b8d5eb74c46cacd505c0471dd3f982f7a0ba438658634a5bc03"
  end

  depends_on "python@3.14"

  resource "urwid" do
    url "https://files.pythonhosted.org/packages/98/b8/9ed1c288eb7e9236ee83a3f847d15dfa879841219b9a7d174c6c2ef33f53/urwid-4.0.2.tar.gz"
    sha256 "6962bd04ab98002326b67a431c59b2fb35e8b5abe2e095feda3ee7d8ea8f1228"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/af/44/c833e6b746ffb654e9abacf7ad6c2480a9c8c42e9637c1ae849964fb4dde/wcwidth-0.8.0.tar.gz"
    sha256 "68a882ff6d14e3d14e0cae590b96a0551be64ce4905408112a8254434a1bdf69"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    output = pipe_output("#{bin}/urlscan -nc", "To:\n\nhttps://github.com/\nSome Text.\nhttps://brew.sh/")
    assert_equal "https://github.com/\nhttps://brew.sh/\n", output
  end
end
