class Goresym < Formula
  desc "Go symbol recovery tool"
  homepage "https://github.com/mandiant/GoReSym"
  url "https://github.com/mandiant/GoReSym/archive/refs/tags/v3.4.tar.gz"
  sha256 "1c6b703ca1e5db08b93a6d602c826ea6dc7eee8502a0b2f4ad358113d8f513fc"
  license "MIT"
  head "https://github.com/mandiant/GoReSym.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "98b249a50ea2b4c57ac775738e702cc44b625c3101bcab574325c7bc1f5c8e1f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = JSON.parse(shell_output("#{bin}/goresym '#{bin}/goresym'"))
    assert_equal output["BuildInfo"]["Main"]["Path"], "github.com/mandiant/GoReSym"
  end
end
