class Exercism < Formula
  desc "Command-line tool to interact with exercism.io"
  homepage "https://exercism.io/cli/"
  url "https://github.com/exercism/cli/archive/refs/tags/v3.5.8.tar.gz"
  sha256 "386cee0117c42a0ead45b6f636f96c2fc20cc5f64f802fcda93c7a0778330f3c"
  license "MIT"
  head "https://github.com/exercism/cli.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e0d23bd7b03d2f58b90294253d4c209bc81e545ced1d155edbaa9f5a3251b87"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "exercism/main.go"

    bash_completion.install "shell/exercism_completion.bash" => "exercism"
    zsh_completion.install "shell/exercism_completion.zsh" => "_exercism"
    fish_completion.install "shell/exercism.fish"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/exercism version")
  end
end
