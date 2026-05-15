class Lazyssh < Formula
  desc "Terminal-based SSH manager"
  homepage "https://github.com/Adembc/lazyssh"
  url "https://github.com/Adembc/lazyssh/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "36cd630b3cd9447e88904171cbb64944aeacbbd62c15db66d8a0e4a4486ffe88"
  license "Apache-2.0"
  head "https://github.com/Adembc/lazyssh.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da8059b43390de3673333fd41d34a70330ac501d2acde8c5567c266970293347"
  end

  depends_on "go" => :build

  def install
    # The commit variable only displays 7 characters, so we can't use #{tap.user} or "Homebrew".
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.gitCommit=brew
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd"
  end

  test do
    # lazyssh is a TUI application
    assert_match "Lazy SSH server picker TUI", shell_output("#{bin}/lazyssh --help")
  end
end
