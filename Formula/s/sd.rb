class Sd < Formula
  desc "Intuitive find & replace CLI"
  homepage "https://github.com/chmln/sd"
  url "https://github.com/chmln/sd/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "defdce484f8c92f265e1282490572575028967c2c55d356111d1e49a3ea9a88e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9679771372ca6b2f7d79dcc3c4bdd4df6bb188bcf60751063f32281c17bfa6a7"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "sd-cli")

    man1.install "gen/sd.1"
    bash_completion.install "gen/completions/sd.bash" => "sd"
    fish_completion.install "gen/completions/sd.fish"
    zsh_completion.install "gen/completions/_sd"
  end

  test do
    assert_equal "after", pipe_output("#{bin}/sd before after", "before")
  end
end
