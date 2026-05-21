class GLs < Formula
  desc "Powerful and cross-platform ls"
  homepage "https://equationzhao.github.io/g/"
  url "https://github.com/Equationzhao/g/archive/refs/tags/v0.31.2.tar.gz"
  sha256 "a1ef8a6872fa80625287c19167152081b833abc4db88910ab145b35b3bbc6da3"
  license "MIT"
  head "https://github.com/Equationzhao/g.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e6d1b1428cc66d5301b4351a87bf23c1a01faa5ef6b64b1bb8363504d6f059c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"g", ldflags: "-s -w")

    bash_completion.install "completions/bash/g-completion.bash" => "g"
    fish_completion.install "completions/fish/g.fish"
    zsh_completion.install "completions/zsh/_g"
    man1.install buildpath.glob("man/*.1.gz")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/g -v")
    touch "test.txt"
    assert_match "test.txt", shell_output("#{bin}/g --no-config --hyperlink=never --color=never --no-icon .")
  end
end
