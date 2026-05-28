class CratesTui < Formula
  desc "TUI for exploring crates.io using Ratatui"
  homepage "https://github.com/ratatui/crates-tui"
  url "https://github.com/ratatui/crates-tui/archive/refs/tags/v0.1.25.tar.gz"
  sha256 "b02e2fa3b7225b5638f9ab8716c3cf21dfb32d96aee140ead2f451005abd58c2"
  license "MIT"
  head "https://github.com/ratatui/crates-tui.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "497ae7cc619e3eaa07ae3d355834ee26f9acaf5fbbc88655f0f03c3b3bc23f2c"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/crates-tui --version")

    begin
      output_log = testpath/"output.log"
      if OS.mac?
        pid = spawn bin/"crates-tui", [:out, :err] => output_log.to_s
      else
        require "pty"
        r, _w, pid = PTY.spawn(bin/"crates-tui", [:out, :err] => output_log.to_s)
        r.winsize = [80, 43]
      end
      sleep 2
      assert_match "New Crates", output_log.read
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
