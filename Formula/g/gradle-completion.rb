class GradleCompletion < Formula
  desc "Bash and Zsh completion for Gradle"
  homepage "https://gradle.org/"
  url "https://github.com/gradle/gradle-completion/archive/refs/tags/v9.5.0.tar.gz"
  sha256 "59354e68f2f0f38a542ea0010be32c14aacfd6184523f209a5e31481964566c8"
  license "MIT"
  compatibility_version 1
  head "https://github.com/gradle/gradle-completion.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88aa46d23d2249a623991cfad02e1fdb2749d76e299ba448933a80af7520e188"
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
