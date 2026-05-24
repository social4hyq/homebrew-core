class Xleak < Formula
  desc "Terminal Excel viewer with an interactive TUI"
  homepage "https://github.com/bgreenwell/xleak"
  url "https://github.com/bgreenwell/xleak/archive/refs/tags/v0.2.6.tar.gz"
  sha256 "9b3985472d1a45aee4d8f5247e49a7cf12127793cd825da44da56685b946e498"
  license "MIT"
  head "https://github.com/bgreenwell/xleak.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "587d6fca60a18d4d9bf5422cca86352e76d0d57f76fd5c0aa2af1c078d371124"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xleak --version")

    resource "testfile" do
      url "https://github.com/chenrui333/github-action-test/releases/download/2025.11.16/test.xlsx"
      sha256 "1231165a2dcf688ba902579f0aafc63fc1481886c2ec7c2aa0b537d9cfd30676"
    end

    testpath.install resource("testfile")
    output = shell_output("#{bin}/xleak #{testpath}/test.xlsx")
    assert_match "Total: 5 rows × 2 columns", output
  end
end
