class Reasonix < Formula
  desc "Cache-first DeepSeek coding agent for the terminal"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.38.2.tar.gz"
  sha256 "d1e0ba9160c7fa5d7d1d9df790f5a02f685cb4924ecba4b7538ffe104cd5c1e3"
  license "MIT"

  # CLI releases are tagged `v*` while desktop releases are tagged `desktop-v*`
  # and are often published first, so only match the `v*` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a7c0d56341840e26e6e68722ad1274f365065ebe2b29a4916486d630f8d3ab2"
  end

  depends_on "go" => :build

  patch do
    file "Patches/reasonix/0001-disable-self-upgrade.patch"
  end

  patch do
    file "Patches/reasonix/0002-use-tmpdir-for-config-locks.patch"
  end

  def install
    ENV["CGO_ENABLED"] = "0"
    ldflags = "-s -w -X main.version=v#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/reasonix"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/reasonix --version")
  end
end
