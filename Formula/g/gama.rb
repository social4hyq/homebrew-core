class Gama < Formula
  desc "Manage your GitHub Actions from Terminal with great UI"
  homepage "https://github.com/termkit/gama"
  url "https://github.com/termkit/gama/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "d2fad1280142b0cc8cb311a5e328590feb0c5a1642c47e3f8e0aaf1b713f6c7b"
  license "GPL-3.0-only"
  head "https://github.com/termkit/gama.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d8cebb403889dfd5dea928552fe4524d7eb143dd3fa0174bf0a6eeedb836917"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    # gama is a TUI app
    #
    # There's no any output to stdout (except for ncurses-like UI) or a file
    # `gama --version` or `gama --help` are not valid options either
    pid = spawn bin/"gama"
    sleep 2
  ensure
    Process.kill("TERM", pid)
    Process.wait pid
  end
end
