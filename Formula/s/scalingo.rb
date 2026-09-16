class Scalingo < Formula
  desc "CLI for working with Scalingo's PaaS"
  homepage "https://doc.scalingo.com/cli"
  url "https://github.com/Scalingo/cli/archive/refs/tags/1.49.0.tar.gz"
  sha256 "60b91a404e4cf169996dcd16e12776e299d47ad33dee8277e5a4bebc7feed6e1"
  license "BSD-4-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19e1ee8dbf262f68a116e9188f988b25a16de0109d73e2af3b6f5fefb7d519d2"
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
