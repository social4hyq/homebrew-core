class PythonArgcomplete < Formula
  include Language::Python::Virtualenv

  desc "Tab completion for Python argparse"
  homepage "https://kislyuk.github.io/argcomplete/"
  url "https://files.pythonhosted.org/packages/38/61/0b9ae6399dd4a58d8c1b1dc5a27d6f2808023d0b5dd3104bb99f45a33ff6/argcomplete-3.6.3.tar.gz"
  sha256 "62e8ed4fd6a45864acc8235409461b72c9a28ee785a2011cc5eb78318786c89c"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ff0a0f823780e3d858bf29213848fc052df5cb1c9fda2f293fb2ed5ed9b4c36"
  end

  deprecate! date: "2026-02-13", because: "does not meet homebrew/core's requirements for Python library formulae"
  disable! date: "2026-08-13", because: "does not meet homebrew/core's requirements for Python library formulae"

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources

    # Bash completions are not compatible with Bash 3 so don't use v1 directory.
    # Ref: https://kislyuk.github.io/argcomplete/#global-completion
    bash_completion_script = "argcomplete/bash_completion.d/_python-argcomplete"
    (share/"bash-completion/completions").install bash_completion_script => "python-argcomplete"
    zsh_completion.install_symlink bash_completion/"python-argcomplete" => "_python-argcomplete"

    # Build an `:all` bottle by replacing comments
    site_packages = libexec/Language::Python.site_packages("python3")
    inreplace site_packages/"argcomplete-#{version}.dist-info/METADATA",
              "/opt/homebrew/bin/bash",
              "$HOMEBREW_PREFIX/bin/bash"
  end

  test do
    output = shell_output("#{bin}/register-python-argcomplete foo")
    assert_match "_python_argcomplete foo", output
  end
end
