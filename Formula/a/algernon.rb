class Algernon < Formula
  desc "Pure Go web server with Lua, Markdown, HTTP/2 and template support"
  homepage "https://github.com/xyproto/algernon"
  url "https://github.com/xyproto/algernon/archive/refs/tags/v1.17.9.tar.gz"
  sha256 "4466f10bbbe278eb79dea571c040e16b154dacca83c736b7c3f8474f5e17f110"
  license "BSD-3-Clause"
  version_scheme 1
  head "https://github.com/xyproto/algernon.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b8cf1580e5a07ad1f7a69ffa7e80acf041d55932b1338930d2e377f5ddadb1a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "-mod=vendor"

    bin.install "desktop/mdview"
  end

  test do
    port = free_port
    pid = spawn bin/"algernon", "-s", "-q", "--httponly", "--boltdb", "tmp.db", "--addr", ":#{port}"
    sleep 20
    output = shell_output("curl -sIm3 -o- http://localhost:#{port}")
    assert_match(/200 OK.*Server: Algernon/m, output)
  ensure
    Process.kill("HUP", pid)
  end
end
