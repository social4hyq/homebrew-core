class Jtbl < Formula
  include Language::Python::Virtualenv

  desc "Convert JSON and JSON Lines to terminal, CSV, HTTP, and markdown tables"
  homepage "https://github.com/kellyjonbrazil/jtbl"
  url "https://files.pythonhosted.org/packages/9e/7c/b21f3383ca611b56dbc281081cca73a24274c3f39654e7fe196d73a67af6/jtbl-1.6.0.tar.gz"
  sha256 "7de0cb08ebb2b3a0658229a8edd4204c6944cbd9e3e04724a9ea235a61c115a5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51851684333bb4b80bd272a3da5c64002d1fdcd86718d7be05dcc7ac5e629d63"
  end

  depends_on "python@3.14"

  resource "tabulate" do
    url "https://files.pythonhosted.org/packages/ec/fe/802052aecb21e3797b8f7902564ab6ea0d60ff8ca23952079064155d1ae1/tabulate-0.9.0.tar.gz"
    sha256 "0095b12bf5966de529c0feb1fa08671671b3368eec77d7ef7ab114be2c068b3c"
  end

  def install
    virtualenv_install_with_resources
    man1.install "man/jtbl.1"

    # Build an `:all` bottle
    packages = libexec/Language::Python.site_packages("python3")
    inreplace packages/"jtbl-#{version}.dist-info/METADATA", "/usr/local/Cellar", "#{HOMEBREW_PREFIX}/Cellar"
  end

  test do
    assert_match <<~EOS, pipe_output(bin/"jtbl", "[{\"a\":1,\"b\":1},{\"a\":2,\"b\":2}]")
        a    b
      ---  ---
        1    1
        2    2
    EOS

    assert_match version.to_s, shell_output("#{bin}/jtbl --version 2>&1", 1)
  end
end
