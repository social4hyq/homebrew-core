class Mark < Formula
  desc "Sync your markdown files with Confluence pages"
  homepage "https://github.com/kovetskiy/mark"
  url "https://github.com/kovetskiy/mark/archive/refs/tags/v16.4.0.tar.gz"
  sha256 "86c0314ebbd18512120c06950d80ec3126bbcc4b62f4f561c7ad4523ffd78b0a"
  license "Apache-2.0"
  head "https://github.com/kovetskiy/mark.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61fade309c63928d35396bc293866f660c5261785adf1a3fbc15e3b7cb665b6d"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/mark"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mark --version")

    (testpath/"test.md").write <<~MARKDOWN
      # Hello Homebrew
    MARKDOWN

    output = shell_output("#{bin}/mark --config nonexistent.yaml sync 2>&1", 1)
    assert_match "confluence password should be specified", output
  end
end
