class Faketty < Formula
  desc "Wrapper to exec a command in a pty, even if redirecting the output"
  homepage "https://github.com/dtolnay/faketty"
  url "https://github.com/dtolnay/faketty/archive/refs/tags/1.0.20.tar.gz"
  sha256 "40a4d1cfa3f265f94895cb1430e9100df43ba0b04c551349cac2973e033a7775"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/dtolnay/faketty.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21fda9af69b212bee13d01bc940181f07a94daab4828e715495f607148d8ba08"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/faketty --version")

    (testpath/"test.sh").write <<~BASH
      if [[ -t 1 ]]; then
        echo "Hello"
      fi
    BASH
    assert_match "Hello", shell_output("#{bin}/faketty bash test.sh | cat")
  end
end
