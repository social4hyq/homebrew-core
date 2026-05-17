class Livereload < Formula
  include Language::Python::Virtualenv

  desc "Local web server in Python"
  homepage "https://github.com/lepture/python-livereload"
  url "https://files.pythonhosted.org/packages/43/6e/f2748665839812a9bbe5c75d3f983edbf3ab05fa5cd2f7c2f36fffdf65bd/livereload-2.7.1.tar.gz"
  sha256 "3d9bf7c05673df06e32bea23b494b8d36ca6d10f7d5c3c8a6989608c09c986a9"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00e17765fb13b27d6832cc9379cadaec59a5187875527d597800e63d998455a6"
  end

  depends_on "python@3.14"

  resource "tornado" do
    url "https://files.pythonhosted.org/packages/f8/f1/3173dfa4a18db4a9b03e5d55325559dab51ee653763bb8745a75af491286/tornado-6.5.5.tar.gz"
    sha256 "192b8f3ea91bd7f1f50c06955416ed76c6b72f96779b962f07f911b91e8d30e9"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"index.html").write <<~EOS
      <h1>Hello, world!</h1>
    EOS

    port = free_port
    pid = spawn bin/"livereload", testpath, "--port=#{port}"

    begin
      sleep 5
      output = shell_output("curl --retry 5 --retry-connrefused -s http://localhost:#{port}/index.html")
      assert_match "<h1>Hello, world!</h1>", output
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
