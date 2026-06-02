class Deck < Formula
  desc "Creates slide deck using Markdown and Google Slides"
  homepage "https://github.com/k1LoW/deck"
  url "https://github.com/k1LoW/deck/archive/refs/tags/v1.24.0.tar.gz"
  sha256 "33e249eb4ac73a450507fa92f14c41f8b962eaa8af9b08ed338041ab293dd555"
  license "MIT"
  head "https://github.com/k1LoW/deck.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72ddf1b7f9830cec5b83dd8e2ad64922436763afc87bd5c39280fcb6375db889"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/deck"

    generate_completions_from_executable(bin/"deck", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/deck --version")
    assert_match "presentation ID is required", shell_output("#{bin}/deck export 2>&1", 1)
  end
end
