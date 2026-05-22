class Md2pdf < Formula
  desc "CLI utility that generates PDF from Markdown"
  homepage "https://github.com/solworktech/md2pdf"
  url "https://github.com/solworktech/md2pdf/archive/refs/tags/v2.2.18.tar.gz"
  sha256 "c231d18742d9b0618bd1feaf1f3ab8864173a838b1847d9dcba6018fe5888f10"
  license "MIT"
  head "https://github.com/solworktech/md2pdf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d05f52679966c2ea7abaaffb1f579e64a00290efa0f05402f746a9d41bd73af7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/md2pdf"
  end

  test do
    (testpath/"test.md").write <<~MARKDOWN
      # Hello World
      This is a test markdown file.
    MARKDOWN

    system bin/"md2pdf", "-i", "test.md", "-o", "test.pdf"
    assert_path_exists testpath/"test.pdf"
  end
end
