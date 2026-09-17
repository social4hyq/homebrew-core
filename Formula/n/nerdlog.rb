class Nerdlog < Formula
  desc "TUI log viewer with timeline histogram and no central server"
  homepage "https://dmitryfrank.com/projects/nerdlog/article"
  url "https://github.com/dimonomid/nerdlog/archive/refs/tags/v1.11.0.tar.gz"
  sha256 "a4027f3667d14eac04f64e2c8312823953caf47ccc6f5b6055f9c28a8c53fda7"
  license "BSD-2-Clause"
  head "https://github.com/dimonomid/nerdlog.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "87efc34b142e917d83158489ff1a6755215207b3d594f1a6939d9d6728bbe28e"
  end

  depends_on "go" => :build

  on_linux do
    depends_on "libx11"
  end

  def install
    ldflags = %W[
      -s -w
      -X github.com/dimonomid/nerdlog/version.version=#{version}
      -X github.com/dimonomid/nerdlog/version.commit=#{tap.user}
      -X github.com/dimonomid/nerdlog/version.date=#{time.iso8601}
      -X github.com/dimonomid/nerdlog/version.builtBy=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/nerdlog"
  end

  test do
    require "pty"
    ENV["TERM"] = "xterm"

    PTY.spawn(bin/"nerdlog") do |r, _w, pid|
      sleep 2
      Process.kill("TERM", pid)
      begin
        output = r.read
        assert_match "Edit query params", output
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end

    assert_match version.to_s, shell_output("#{bin}/nerdlog --version")
  end
end
