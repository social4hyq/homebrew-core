class Tuisky < Formula
  desc "TUI client for bluesky"
  homepage "https://github.com/sugyan/tuisky"
  url "https://github.com/sugyan/tuisky/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "b3db8969aa5152692f7178a17f51d694a2cc4e06bb8ff18e43b0f4c7a5d83fa8"
  license "MIT"
  head "https://github.com/sugyan/tuisky.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "63e77d3fdb4eb02334a952cba0a690db55188f8edb615538cf54304dda50f7d5"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args

    pkgetc.install "config/example.config.toml" => "config.toml"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tuisky --version")

    begin
      output_log = testpath/"output.log"
      if OS.mac?
        pid = spawn bin/"tuisky", [:out, :err] => output_log.to_s
      else
        require "pty"
        r, _w, pid = PTY.spawn bin/"tuisky", [:out, :err] => output_log.to_s
        r.winsize = [80, 130]
      end
      sleep 1
      assert_match "https://bsky.social", output_log.read
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
