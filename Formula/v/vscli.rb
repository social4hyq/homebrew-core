class Vscli < Formula
  desc "CLI/TUI that launches VSCode projects, with a focus on dev containers"
  homepage "https://github.com/michidk/vscli"
  url "https://github.com/michidk/vscli/archive/refs/tags/v1.3.2.tar.gz"
  sha256 "c78fe7e92958cd76fbc3cd4a61112e96f770af64fe03060337a60f26609a6bc2"
  license "MIT"
  head "https://github.com/michidk/vscli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b0addb1175232b2518479eaccccece02d367906a2abc20ed46fc189a94b5dd1"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vscli --version")

    output = shell_output("#{bin}/vscli open --dry-run 2>&1", 1)
    assert_match "No dev container found, opening on host system with Visual Studio Code...", output
  end
end
