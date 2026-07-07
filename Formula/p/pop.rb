class Pop < Formula
  desc "Send emails from your terminal"
  homepage "https://github.com/charmbracelet/pop"
  url "https://github.com/charmbracelet/pop/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "b7f68883e55004fd538faa78227afd474e4222e567c5cdd9d6c15f52c2befe45"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08490ccab773c7c3ccb6a723aed9669e2ef36045150baa43a5e03c0a539be0df"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"pop", shell_parameter_format: :cobra)
    (man1/"pop.1").write Utils.safe_popen_read(bin/"pop", "man")
  end

  test do
    assert_match " Charm Pop  Hello!",
      shell_output("#{bin}/pop --body 'hi' --subject 'Hello' 2>&1", 1).chomp

    assert_match version.to_s, shell_output("#{bin}/pop --version")
  end
end
