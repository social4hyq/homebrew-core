class Pure < Formula
  desc "Pretty, minimal and fast ZSH prompt"
  homepage "https://github.com/sindresorhus/pure"
  url "https://github.com/sindresorhus/pure/archive/refs/tags/v1.28.3.tar.gz"
  sha256 "738b523c59823083de490b3eb6c1116fc45c342e6b32a7d3cf05fdd0f8aa75a8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18321d0f62256d98610c56d792feb60a3e34c3fd5e654079c780d5f5e523c1c6"
  end

  depends_on "zsh" => :test
  depends_on "zsh-async"

  def install
    zsh_function.install "pure.zsh" => "prompt_pure_setup"
  end

  test do
    zsh_command = "setopt prompt_subst; autoload -U promptinit; promptinit && prompt -p pure"
    assert_match "❯", shell_output("zsh -c '#{zsh_command}'")
  end
end
