class Mark < Formula
  desc "Sync your markdown files with Confluence pages"
  homepage "https://github.com/kovetskiy/mark"
  url "https://github.com/kovetskiy/mark/archive/refs/tags/v16.5.1.tar.gz"
  sha256 "bd549148eb3f42ca1881230e95f4b3d0e5da8dcdd91f5d6fb8ca77f47146a40e"
  license "Apache-2.0"
  head "https://github.com/kovetskiy/mark.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "04e268b2e9f4e1c90e245ed7f2c1a78cbb1fde606cb31fb1cd0820c22915b9d7"
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
