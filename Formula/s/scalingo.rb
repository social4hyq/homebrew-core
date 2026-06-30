class Scalingo < Formula
  desc "CLI for working with Scalingo's PaaS"
  homepage "https://doc.scalingo.com/cli"
  url "https://github.com/Scalingo/cli/archive/refs/tags/1.47.0.tar.gz"
  sha256 "2931dc044dda655ab85dae572e5f01fb13942392bdea379231306c29d97c3efd"
  license "BSD-4-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a287dcd56fcd381c8c920e4ed6d282555b59fcb19b5e0050861ea742304f0fe7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "scalingo/main.go"

    bash_completion.install "cmd/autocomplete/scripts/scalingo_complete.bash" => "scalingo"
    zsh_completion.install "cmd/autocomplete/scripts/scalingo_complete.zsh" => "_scalingo"
  end

  test do
    expected = <<~END
      ┌───────────────────┬───────┐
      │ CONFIGURATION KEY │ VALUE │
      ├───────────────────┼───────┤
      │ region            │       │
      └───────────────────┴───────┘
    END
    assert_equal expected, shell_output("#{bin}/scalingo config")
  end
end
