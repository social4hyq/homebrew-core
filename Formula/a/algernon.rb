class Algernon < Formula
  desc "Pure Go web server with Lua, Markdown, HTTP/2 and template support"
  homepage "https://github.com/xyproto/algernon"
  url "https://github.com/xyproto/algernon/archive/refs/tags/v1.17.8.tar.gz"
  sha256 "54a3b45ccc75266e831c60747b54baf176f060b08eac9663e5171772c10fbb4a"
  license "BSD-3-Clause"
  version_scheme 1
  head "https://github.com/xyproto/algernon.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "efdad361f7ed68e9bf1ee07dae068e1872cfa3514b3cad17628754ed70a24c6d"
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
