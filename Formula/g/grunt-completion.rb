class GruntCompletion < Formula
  desc "Bash and Zsh completion for Grunt"
  homepage "https://gruntjs.com/"
  url "https://github.com/gruntjs/grunt-cli/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "0ed2f1bbe6ba85c5b2b3ae1233c52b7622db092c078aafbba75dbb435a6a9d20"
  license "MIT"
  head "https://github.com/gruntjs/grunt-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "521d16a13412de256693cd089cdb504ee658f691032620251284d0f02ff07560"
  end

  def install
    bash_completion.install "completion/bash" => "grunt"
    zsh_completion.install "completion/zsh" => "_grunt"
  end

  test do
    assert_match "-F _grunt_completions",
      shell_output("bash -c 'source #{bash_completion}/grunt && complete -p grunt'")
  end
end
