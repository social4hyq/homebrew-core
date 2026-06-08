class HtmlToMarkdown < Formula
  desc "Transforms HTML (even entire websites) into clean, readable Markdown"
  homepage "https://html-to-markdown.com"
  url "https://github.com/JohannesKaufmann/html-to-markdown/archive/refs/tags/v2.5.2.tar.gz"
  sha256 "1086b066a17bf49d8bec8fa493e07a54580924ad866ed7e8052692accba706dc"
  license "MIT"
  head "https://github.com/JohannesKaufmann/html-to-markdown.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4311ccebe3462379c52dcc948ec0dc3826c5b241574f0e2461b6da90226c9fce"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.date=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"html2markdown"), "./cli/html2markdown"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/html2markdown --version")

    output = shell_output("echo \"<strong>important</strong>\" | #{bin}/html2markdown")
    assert_match "**important**", output
  end
end
