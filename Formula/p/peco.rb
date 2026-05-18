class Peco < Formula
  desc "Simplistic interactive filtering tool"
  homepage "https://github.com/peco/peco"
  url "https://github.com/peco/peco/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "480ba339c5b15ebb9eada276d5e25315ee5c36e878d86dcfc1ea17f54a27197a"
  license "MIT"
  head "https://github.com/peco/peco.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfb8177fa2ec394ff7a7a8a9284c7052da0df41a1be9aea211f387fc367893d8"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/peco/peco.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/peco"
  end

  test do
    system bin/"peco", "--version"

    ENV["TERM"] = "xterm"
    assert_match "homebrew", pipe_output("#{bin}/peco --select-1", "homebrew\n", 0)
  end
end
