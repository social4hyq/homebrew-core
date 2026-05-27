class Pastel < Formula
  desc "Command-line tool to generate, analyze, convert and manipulate colors"
  homepage "https://github.com/sharkdp/pastel"
  url "https://github.com/sharkdp/pastel/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "2903853f24d742fe955edd9bea17947eb8f3f44000a8ac528d16f2ea1e52b78b"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/sharkdp/pastel.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae33b0e6b7892f5d0d9bdd6350122d298ad752db22dfff7dd157547132f46192"
  end

  depends_on "rust" => :build

  def install
    ENV["SHELL_COMPLETIONS_DIR"] = buildpath/"completions"

    system "cargo", "install", *std_cargo_args

    bash_completion.install "completions/pastel.bash" => "pastel"
    zsh_completion.install "completions/_pastel"
    fish_completion.install "completions/pastel.fish"
  end

  test do
    output = shell_output("#{bin}/pastel format hex rebeccapurple").strip

    assert_equal "#663399", output
  end
end
