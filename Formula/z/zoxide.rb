class Zoxide < Formula
  desc "Shell extension to navigate your filesystem faster"
  homepage "https://github.com/ajeetdsouza/zoxide"
  url "https://github.com/ajeetdsouza/zoxide/archive/refs/tags/v0.9.9.tar.gz"
  sha256 "eddc76e94db58567503a3893ecac77c572f427f3a4eabdfc762f6773abf12c63"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71e618975f15ffed7c26d65d04b0873e41b0633ec7292ec1e6fdb0aeaf26c8b5"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    bash_completion.install "contrib/completions/zoxide.bash" => "zoxide"
    zsh_completion.install "contrib/completions/_zoxide"
    fish_completion.install "contrib/completions/zoxide.fish"
    share.install "man"
  end

  test do
    assert_empty shell_output("#{bin}/zoxide add /").strip
    assert_equal "/", shell_output("#{bin}/zoxide query").strip
  end
end
