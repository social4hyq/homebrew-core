class Matcha < Formula
  desc "Daily digest generator for your RSS feeds"
  homepage "https://github.com/piqoni/matcha"
  url "https://github.com/piqoni/matcha/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "be0f8674638bdb1c34bd523ca6622f8d73efcfbef18d8002558af2b295caa5e3"
  license "MIT"
  head "https://github.com/piqoni/matcha.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67f3294d1d3522aa55ee1a141324541dd813a244c00ee546b8b3fe38a0633c47"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Hacker News: Best", shell_output("#{bin}/matcha -t")
  end
end
