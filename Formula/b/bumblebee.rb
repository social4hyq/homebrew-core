class Bumblebee < Formula
  desc "Read-only developer endpoint scanner for supply-chain exposure"
  homepage "https://github.com/perplexityai/bumblebee"
  url "https://github.com/perplexityai/bumblebee/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "6ed6c27ae6b5c040eb018e247c09e53baa2fdea43bba1c3e63515d14d46157d2"
  license "Apache-2.0"
  head "https://github.com/perplexityai/bumblebee.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23b6060bc8f7203de754f33b741ff97fc7d3e4a28db8ded920298013cf2ec6b3"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=v#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/bumblebee"
    pkgshare.install "threat_intel"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bumblebee version")
    assert_match "selftest OK", shell_output("#{bin}/bumblebee selftest")
  end
end
