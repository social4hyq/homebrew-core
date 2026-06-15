class Television < Formula
  desc "General purpose fuzzy finder TUI"
  homepage "https://github.com/alexpasmantier/television"
  url "https://github.com/alexpasmantier/television/archive/refs/tags/0.15.9.tar.gz"
  sha256 "5f46cbe7b14e1d6e3958f436b1d6ed8af86e9914d7d2aee5a9379e8e1772072d"
  license "MIT"
  head "https://github.com/alexpasmantier/television.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afb6da4ea8c6d4eb53930dd8e45385f3950c1a2784e9bc63ae6fcd05638c1250"
  end

  depends_on "rust" => :build

  conflicts_with "tidy-viewer", because: "both install `tv` binaries"

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/tv.1"

    generate_completions_from_executable(bin/"tv", "init")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tv -V")

    output = shell_output("#{bin}/tv help")
    assert_match "fuzzy finder for the terminal", output
  end
end
