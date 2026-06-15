class GitRemoteHg < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Transparent bidirectional bridge between Git and Mercurial"
  homepage "https://github.com/felipec/git-remote-hg"
  url "https://github.com/felipec/git-remote-hg/archive/refs/tags/v0.7.tar.gz"
  sha256 "ada593c2462bed5083ab0fbd50b9406b8e83b04a6c882de80483e7c77ce8bf07"
  license "GPL-2.0-only"
  revision 2
  head "https://github.com/felipec/git-remote-hg.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "733ad1cd8ba751583cca7efd436d67e5e2290cc10579f42209e90ea78a244dc5"
  end

  depends_on "mercurial" => :test
  depends_on "asciidoctor" => :build
  depends_on "python@3.14"

  conflicts_with "git-cinnabar", because: "both install `git-remote-hg` binaries"

  # TODO: Switch back to formula after Mercurial 7.2+ is supported
  # Currently fails with "mercurial.error.BundleUnknownFeatureError: b'changegroup'"
  resource "mercurial" do
    url "https://www.mercurial-scm.org/release/mercurial-7.1.2.tar.gz"
    sha256 "ce27b9a4767cf2ea496b51468bae512fa6a6eaf0891e49f8961dc694b4dc81ca"
  end

  def install
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resource("mercurial")
    venv_python = venv.root/"bin/python"

    rewrite_shebang python_shebang_rewrite_info(venv_python), "git-remote-hg"
    system "make", "install", "prefix=#{prefix}"

    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"
    system "make", "install-doc", "prefix=#{prefix}"
  end

   test do
    system "hg", "init", "local-hg-repo"
    (testpath/"local-hg-repo/test.txt").write "Hello Homebrew"
    
    system "hg", "--cwd", "local-hg-repo", "commit", "--config", "ui.username=Homebrew Test <test@homebrew.sh>", "-A", "-m", "Initial commit"

    system "git", "clone", "hg::#{testpath}/local-hg-repo", "git-repo"
    assert_path_exists testpath/"git-repo/test.txt"
  end

  test do
    system "hg", "init", "local-hg-repo"
    (testpath/"local-hg-repo/test.txt").write "Hello"
    
    system "hg", "--cwd", "local-hg-repo", "commit", "--config", "ui.username=Test User <user@example.com>", "-A", "-m", "Initial commit"

    system "git", "clone", "hg::#{testpath}/local-hg-repo", "git-repo"
    assert_path_exists testpath/"git-repo/test.txt"
  end
end
