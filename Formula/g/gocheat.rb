class Gocheat < Formula
  desc "TUI Cheatsheet for keybindings, hotkeys and more"
  homepage "https://github.com/Achno/gocheat"
  url "https://github.com/Achno/gocheat/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "338e7123411c4a5fb9fe387f7155f1e48d511845fe7f2383718d16abf54b26fc"
  license "MIT"
  head "https://github.com/Achno/gocheat.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e969f2cb3cfa01af0af38dbba7f7aa2b12881749e2899eea3b8cc3df377a9ab"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output_log = testpath/"output.log"
    pid = if OS.mac?
      spawn bin/"gocheat", [:out, :err] => output_log.to_s
    else
      require "pty"
      PTY.spawn(bin/"gocheat", [:out, :err] => output_log.to_s).last
    end
    sleep 1
    assert_match "Description : keybinding", output_log.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
