class Vscli < Formula
  desc "CLI/TUI that launches VSCode projects, with a focus on dev containers"
  homepage "https://github.com/michidk/vscli"
  url "https://github.com/michidk/vscli/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "af089ab9ccf80b24399575d1cea3014974d04ab73a4688259c53a2525da11d0d"
  license "MIT"
  head "https://github.com/michidk/vscli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35b1b5d4191d3c7761dda84d282b6e695ff5553e47ec76201032580b8efc5de8"
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
