class Wush < Formula
  desc "Transfer files between computers via WireGuard"
  homepage "https://github.com/coder/wush"
  url "https://github.com/coder/wush/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "77d5a912465d1e8ec478252a9a69a04d39af75a126ac9ed94823f33a60b3d8f9"
  license "CC0-1.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bca3d3dc0059da6d2f0778f6c4367e25e5ca096d4f0f97d14bc07c30fce33f53"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/wush"
  end

  test do
    read, write = IO.pipe

    pid = fork do
      exec bin/"wush", "serve", out: write, err: write
    end

    output = read.gets
    assert_includes output, "Picked DERP region"
  ensure
    Process.kill "TERM", pid
    Process.wait pid
  end
end
