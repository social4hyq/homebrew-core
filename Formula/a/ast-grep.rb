class AstGrep < Formula
  desc "Code searching, linting, rewriting"
  homepage "https://github.com/ast-grep/ast-grep"
  url "https://github.com/ast-grep/ast-grep/archive/refs/tags/0.44.0.tar.gz"
  sha256 "1cc8d5d6a759c6d99c676bcec09fbf1fc72e023804e54480146fd62b300fce95"
  license "MIT"
  head "https://github.com/ast-grep/ast-grep.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8289450f4186e86891fb83684986d9552a9b0d4ba076012978440e733f1df201"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/cli")

    generate_completions_from_executable(bin/"ast-grep", "completions", shells: [:bash, :zsh, :fish, :pwsh])
  end

  test do
    (testpath/"hi.js").write("console.log('it is me')")
    system bin/"ast-grep", "run", "-l", "js", "-p console.log", (testpath/"hi.js")

    assert_match version.to_s, shell_output("#{bin}/ast-grep --version")
  end
end
