class Lazycontainer < Formula
  desc "Terminal UI for Apple Containers"
  homepage "https://github.com/andreybleme/lazycontainer"
  url "https://github.com/andreybleme/lazycontainer/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "b7aa9e050f947c7e99c7059eed75477711e1f558d0b0c90098421bee196e1a64"
  license "MIT"
  head "https://github.com/andreybleme/lazycontainer.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23b30625c06c1c475b21bd2b553161130921c00cb227685b9bae293546073733"
  end

  depends_on "go" => :build

  # limited by Apple Containers support:
  depends_on arch: :arm64
  depends_on macos: :tahoe

  def install
    system "go", "build", *std_go_args, "./cmd"
  end

  test do
    require "pty"

    PTY.spawn(bin/"lazycontainer") do |r, _w, pid|
      out = r.readpartial(1024)
      assert_match "Error listing containers", out
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
