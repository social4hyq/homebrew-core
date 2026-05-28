class OpenapiTui < Formula
  desc "TUI to list, browse and run APIs defined with openapi spec"
  homepage "https://github.com/zaghaghi/openapi-tui"
  url "https://github.com/zaghaghi/openapi-tui/archive/refs/tags/0.10.2.tar.gz"
  sha256 "e9ca7bc160ca6fdf50f7534318589fcb725564c05b81f40742e37a422f35a191"
  license "MIT"
  head "https://github.com/zaghaghi/openapi-tui.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43c1ff31c4cd18cb51fac377e6015e7f2e5feabfd501b051f3aedb910c4f0326"
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
    assert_match version.to_s, shell_output("#{bin}/openapi-tui --version")

    openapi_url = "https://raw.githubusercontent.com/Tufin/oasdiff/8fdb99634d0f7f827810ee1ba7b23aa4ada8b124/data/openapi-test1.yaml"

    begin
      output_log = testpath/"output.log"
      if OS.mac?
        pid = spawn bin/"openapi-tui", "--input", openapi_url, [:out, :err] => output_log.to_s
      else
        require "pty"
        r, _w, pid = PTY.spawn bin/"openapi-tui", "--input", openapi_url, [:out, :err] => output_log.to_s
        r.winsize = [80, 43]
      end
      sleep 1
      assert_match "APIs", output_log.read
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
