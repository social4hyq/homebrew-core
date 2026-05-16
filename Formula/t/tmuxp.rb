class Tmuxp < Formula
  include Language::Python::Virtualenv

  desc "Tmux session manager. Built on libtmux"
  homepage "https://tmuxp.git-pull.com/"
  url "https://files.pythonhosted.org/packages/e2/1b/b569e807b0e78918ebfbb3667237095fd847ce7280887de2ec93257445f9/tmuxp-1.68.0.tar.gz"
  sha256 "10adbf1fe59f46f6f92879c8c4f7799d4d6f7b70d278643a3853edd048c1876f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "763e0e00c302667883f53706ec8afdd521a015f17c241370637b3677febfd381"
  end

  depends_on "libyaml"
  depends_on "python@3.14"
  depends_on "tmux"

  resource "libtmux" do
    url "https://files.pythonhosted.org/packages/7d/62/896e1e0412dd76c88926604d5a231feb9b116d6f32abe19054e244504dbc/libtmux-0.56.0.tar.gz"
    sha256 "bddf52214405e4f64850826d44cbc958d4a01c53432983cee0e2856bdbbaaedb"
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
