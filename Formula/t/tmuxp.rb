class Tmuxp < Formula
  include Language::Python::Virtualenv

  desc "Tmux session manager. Built on libtmux"
  homepage "https://tmuxp.git-pull.com/"
  url "https://files.pythonhosted.org/packages/94/6c/11511988cd537976448ce8bc5c58978d63094b95a6be9f71f6a533d1c9d2/tmuxp-1.71.0.tar.gz"
  sha256 "f8db2be2035e9bf801e9932b7b9deb7ee33c2b0922bbce9a1899abc62151a2b6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "604501d6bbc6b5af6e00ab2c08087d2f5796f95435c985f63d4ce14ecf3f34a2"
  end

  depends_on "libyaml"
  depends_on "python@3.14"
  depends_on "tmux"

  resource "libtmux" do
    url "https://files.pythonhosted.org/packages/3b/a3/4112c3e30f7620eaaef9e7445dc1c040a006ad83a071697136652014ea5a/libtmux-0.59.0.tar.gz"
    sha256 "bc279de9626408a5460c752ef1cc1884fc93ad00f5cc43a6170f619bc1617cf1"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tmuxp --version")

    (testpath/"test_session.yaml").write <<~YAML
      session_name: 2-pane-vertical
      windows:
      - window_name: my test window
        panes:
          - echo hello
          - echo hello
    YAML

    system bin/"tmuxp", "debug-info"
    system bin/"tmuxp", "convert", "--yes", "test_session.yaml"
    assert_path_exists testpath/"test_session.json"
  end
end
