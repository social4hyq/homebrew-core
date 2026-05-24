class KitchenCompletion < Formula
  desc "Bash completion for Kitchen"
  homepage "https://github.com/MarkBorcherding/test-kitchen-bash-completion"
  url "https://github.com/MarkBorcherding/test-kitchen-bash-completion/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "6a9789359dab220df0afad25385dd3959012cfa6433c8c96e4970010b8cfc483"
  license "MIT"
  head "https://github.com/MarkBorcherding/test-kitchen-bash-completion.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be3bea548f6caf3a6192021d4af26092edbb42dde2db59ca27ab3b479d6d33ae"
  end

  def install
    bash_completion.install "kitchen-completion.bash" => "kitchen"
  end

  test do
    assert_match "-F __kitchen_options",
      shell_output("bash -c 'source #{bash_completion}/kitchen && complete -p kitchen'")
  end
end
