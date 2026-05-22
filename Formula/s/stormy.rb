class Stormy < Formula
  desc "Minimal, customizable and neofetch-like weather CLI based on rainy"
  homepage "https://github.com/ashish0kumar/stormy"
  url "https://github.com/ashish0kumar/stormy/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "b53d479643599c733090ebf54eebd582eb3fe5faf5148015770f0ab594dc6464"
  license "MIT"
  head "https://github.com/ashish0kumar/stormy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cff64a91842828163dd8a9b384a5563af00b2179252ae2b101d7241ad0a02c63"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Weather", shell_output("#{bin}/stormy --city London")
    assert_match "Error: City must be set in the config file or via command line flags",
      shell_output("#{bin}/stormy 2>&1", 1)
  end
end
