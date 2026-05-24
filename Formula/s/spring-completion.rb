class SpringCompletion < Formula
  desc "Bash completion for Spring"
  homepage "https://github.com/jacaetevha/spring_bash_completion"
  url "https://github.com/jacaetevha/spring_bash_completion/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "a97b256dbdaca894dfa22bd96a6705ebf4f94fa8206d05f41927f062c3dd60bf"
  license "Unlicense"
  head "https://github.com/jacaetevha/spring_bash_completion.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b85c3439198f2753e1b794fc4bc48b308a8899509d60b9b070f24c88b06e7f1f"
  end

  def install
    bash_completion.install "spring.bash" => "spring"
  end

  test do
    assert_match "-F _spring",
      shell_output("bash -c 'source #{bash_completion}/spring && complete -p spring'")
  end
end
