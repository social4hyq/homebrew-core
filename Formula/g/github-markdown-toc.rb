class GithubMarkdownToc < Formula
  desc "Easy TOC creation for GitHub README.md (in go)"
  homepage "https://github.com/ekalinin/github-markdown-toc.go"
  url "https://github.com/ekalinin/github-markdown-toc.go/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "62f34f003912244c8d6d94cad9a273ddb3f29f6f01133d16fdefd0c017030526"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ba6550c1835a7f84a96b6c6a58f1798f62e18db229af2d31b6a99070434ebffa"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"gh-md-toc"), "./cmd/gh-md-toc"
  end

  test do
    (testpath/"README.md").write("# Header")
    assert_match version.to_s, shell_output("#{bin}/gh-md-toc --version 2>&1")
    assert_match "* [Header](#header)", shell_output("#{bin}/gh-md-toc ./README.md")
  end
end
