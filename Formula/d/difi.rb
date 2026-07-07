class Difi < Formula
  desc "Pixel-perfect terminal diff viewer"
  homepage "https://github.com/oug-t/difi"
  url "https://github.com/oug-t/difi/archive/refs/tags/v0.2.10.tar.gz"
  sha256 "ef39527c9667f8b6aebb567f03046703bec1f8409e533408491973e0fe9500c2"
  license "MIT"
  head "https://github.com/oug-t/difi.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f44401b2344bf5bfd5bbd37638d42407d16deda008ea1e2cc6c6f83f507b3c9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/difi"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/difi -version")

    system "git", "init"
    system "git", "config", "user.email", "test@example.com"
    system "git", "config", "user.name", "Test"

    (testpath/"file.txt").write("one")
    system "git", "add", "file.txt"
    system "git", "commit", "-m", "init"

    File.write(testpath/"file.txt", "two")
    system "git", "commit", "-am", "change"

    output = shell_output("#{bin}/difi --plain HEAD~1")
    assert_match "file.txt", output
  end
end
