class Snakeviz < Formula
  include Language::Python::Virtualenv

  desc "Web-based viewer for Python profiler output"
  homepage "https://jiffyclub.github.io/snakeviz/"
  url "https://files.pythonhosted.org/packages/04/06/82f56563b16d33c2586ac2615a3034a83a4ff1969b84c8d79339e5d07d73/snakeviz-2.2.2.tar.gz"
  sha256 "08028c6f8e34a032ff14757a38424770abb8662fb2818985aeea0d9bc13a7d83"
  license "BSD-3-Clause"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ffa1b081eff755240db758ebb23d17f45f2b0e6d5de97cb91d88e9b08d07e20"
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
    require "cgi"
    system bin/"snakeviz", "--version"
    system "python3.14", "-m", "cProfile", "-o", "output.prof", "-m", "cProfile"

    port = free_port

    output_file = testpath/"output.prof"

    pid = fork do
      exec bin/"snakeviz", "--port", port.to_s, "--server", output_file
    end
    sleep 3
    output = shell_output("curl -s http://localhost:#{port}/snakeviz/#{ERB::Util.url_encode output_file}")
    assert_match "cProfile", output
  ensure
    Process.kill("HUP", pid)
  end
end
