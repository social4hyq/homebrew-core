class MavenCompletion < Formula
  desc "Bash completion for Maven"
  homepage "https://github.com/juven/maven-bash-completion"
  url "https://github.com/juven/maven-bash-completion/archive/refs/tags/20200420.tar.gz"
  sha256 "eb4ef412d140e19e7d3ce23adb7f8fcce566f44388cfdc8c1e766a3c4b183d3d"
  license "Apache-2.0"
  head "https://github.com/juven/maven-bash-completion.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "40e70414a49e6f507a061315b2068f8296b733b845b23ef897087a3d643c3d52"
  end

  def install
    bash_completion.install "bash_completion.bash" => "maven"
  end

  test do
    assert_match "-F _mvn",
      shell_output("bash -c 'source #{bash_completion}/maven && complete -p mvn'")
  end
end
