class GradleCompletion < Formula
  desc "Bash and Zsh completion for Gradle"
  homepage "https://gradle.org/"
  url "https://github.com/gradle/gradle-completion/archive/refs/tags/v9.6.1.tar.gz"
  sha256 "f6692560abd24b0fe85f57b4b12f9382924ac960c70f85956bbb1e6bd19fb13f"
  license "MIT"
  compatibility_version 1
  head "https://github.com/gradle/gradle-completion.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84e95c07e475e2576494b60770394999de8ac27c585a218714c7fd4e53507b80"
  end

  def install
    bash_completion.install "gradle-completion.bash" => "gradle"
    zsh_completion.install "_gradle" => "_gradle"
  end

  test do
    assert_match "-F _gradle",
      shell_output("bash -c 'source #{bash_completion}/gradle && complete -p gradle'")
  end
end
