class Proxify < Formula
  desc "Portable proxy for capturing, manipulating, and replaying HTTP/HTTPS traffic"
  homepage "https://github.com/projectdiscovery/proxify"
  url "https://github.com/projectdiscovery/proxify/archive/refs/tags/v0.0.16.tar.gz"
  sha256 "a156d8094ac5a31bc92029c1a9e02300caa5e2f189dc13949410d792e9f4e63c"
  license "MIT"
  head "https://github.com/projectdiscovery/proxify.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5b0e1e73ef54a7c9bb8edbc60ae52c055de6c4b998441574fefd895bcce681ec"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/proxify"
  end

  test do
    # Other commands start proxify, which causes Homebrew CI to time out
    assert_match version.to_s, shell_output("#{bin}/proxify -version 2>&1")
    assert_match "given config file 'brew' does not exist", shell_output("#{bin}/proxify -config brew 2>&1", 1)
  end
end
