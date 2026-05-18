class ZshHistoryEnquirer < Formula
  desc "Zsh plugin that enhances history search interaction"
  homepage "https://zsh-history-enquirer.zthxxx.me"
  url "https://registry.npmjs.org/zsh-history-enquirer/-/zsh-history-enquirer-1.3.1.tgz"
  sha256 "dab146c955f167089bbe8f24a79b4a6cabe4c9ce2b8b246eb9fca27eca2bc4ae"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a3eaf01d0d2f115b14d28c94e7c92e8a785f6c2b9ba8e3255020720f738ae44"
  end

  depends_on "node"

  uses_from_macos "zsh"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
    zsh_function.install "zsh-history-enquirer.plugin.zsh" => "history_enquire"
  end

  def caveats
    <<~EOS
      To activate zsh-history-enquirer, add the following to your .zshrc:
        autoload -U history_enquire
        history_enquire
    EOS
  end

  test do
    zsh_command = "autoload -U history_enquire; where history_enquire"
    assert_match "history_enquire", shell_output("zsh -ic '#{zsh_command}'")
  end
end
