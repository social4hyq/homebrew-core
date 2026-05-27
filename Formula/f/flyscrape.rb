class Flyscrape < Formula
  desc "Standalone and scriptable web scraper"
  homepage "https://flyscrape.com/"
  url "https://github.com/philippta/flyscrape/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "cbc8c977c55f9617ce29f2178c00c22bda4bd9d1987f37c688580c2848653e17"
  license "MPL-2.0"
  head "https://github.com/philippta/flyscrape.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d541adfb127d707e738595e9d3de2443890f94c21f9fdcc31196f8e580398d1e"
  end

  depends_on "go" => :build

  uses_from_macos "sqlite"

  def install
    tags = "osusergo,netgo,sqlite_omit_load_extension"
    system "go", "build", *std_go_args(ldflags: "-s -w", tags:), "./cmd/flyscrape"

    pkgshare.install "examples"
  end

  test do
    test_config = pkgshare/"examples/hackernews.js"
    return_status = OS.mac? ? 1 : 0
    output = shell_output("#{bin}/flyscrape run #{test_config} 2>&1", return_status)
    expected = if OS.mac?
      "failed to create database file"
    else
      "\"url\": \"https://news.ycombinator.com/\""
    end
    assert_match expected, output
  end
end
