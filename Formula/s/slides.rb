class Slides < Formula
  desc "Terminal based presentation tool"
  homepage "https://maaslalani.com/slides/"
  url "https://github.com/maaslalani/slides/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "fcce0dbbe767e0b1f0800e4ea934ee9babbfb18ab2ec4b343e3cd6359cd48330"
  license "MIT"
  head "https://github.com/maaslalani/slides.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f67a99f120b23db04552c1445ae8bacdcdd17469f12279eae89301850e6e5684"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    (testpath/"test.md").write <<~MARKDOWN
      # Slide 1
      Content

      ---

      # Slide 2
      More Content
    MARKDOWN

    # Bubbletea-based apps are hard to test even under PTY.spawn (or via
    # expect) because they rely on vt100-like answerback support, such as
    # "<ESC>[6n" to report the cursor position. For now we just run the command
    # for a second and see that it tried to send some ANSI out of it.
    require "pty"
    PTY.spawn(bin/"slides", "test.md") do |r, _, pid|
      sleep 1
      Process.kill("TERM", pid)
      assert_match(/\e\[/, r.read_nonblock(1024))
    end
  end
end
