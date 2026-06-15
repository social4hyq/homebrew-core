class Viddy < Formula
  desc "Modern watch command"
  homepage "https://github.com/sachaos/viddy"
  url "https://github.com/sachaos/viddy/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "c5de99390846029aacb23789ce20267142dc89f647c519a0a0bb4821334cc6e5"
  license "MIT"
  head "https://github.com/sachaos/viddy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4b1e488aa31944cf31ef29d7823a7a7faa832e4787f511872e8b69288217cc5b"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    begin
      pid = spawn bin/"viddy", "--interval", "1", "date"
      sleep 2
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end

    assert_match "viddy #{version}", shell_output("#{bin}/viddy --version")
  end
end
