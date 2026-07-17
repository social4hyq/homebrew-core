class Pop < Formula
  desc "Send emails from your terminal"
  homepage "https://github.com/charmbracelet/pop"
  url "https://github.com/charmbracelet/pop/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "1ac694148e286bf9bd75387a98ee66b41c554e989fae41314f4b762210e14436"
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
