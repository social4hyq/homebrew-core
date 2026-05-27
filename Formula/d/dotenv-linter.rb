class DotenvLinter < Formula
  desc "Lightning-fast linter for .env files written in Rust"
  homepage "https://dotenv-linter.github.io"
  url "https://github.com/dotenv-linter/dotenv-linter/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "c10f63e84a877b630986a59680df20ee3f49ae3f89daa8d7e65f427d31b13a32"
  license "MIT"
  head "https://github.com/dotenv-linter/dotenv-linter.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8957754287889bba60b77fefea4eaf5ef58b70aedafbdde3aec28a618ef0c475"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "dotenv-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dotenv-linter --version")

    (testpath/".env").write <<~EOS
      FOO=bar
      FOO=bar
      BAR=foo
    EOS

    (testpath/".env.test").write <<~EOS
      1FOO=bar
      _FOO=bar
    EOS

    output = shell_output("#{bin}/dotenv-linter check .env .env.test", 1)
    assert_match(/\.env:2\s+DuplicatedKey/, output)
    assert_match(/\.env:3\s+UnorderedKey/, output)
    assert_match(/\.env.test:1\s+LeadingCharacter/, output)
  end
end
