class Reasonix < Formula
  desc "Cache-first DeepSeek coding agent for the terminal"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.38.11.tar.gz"
  sha256 "1fd0f9e23cf0c927af9e287ff00816ff78fa142c6c98be59e507c93d52379368"
  license "MIT"

  # CLI releases are tagged `v*` while desktop releases are tagged `desktop-v*`
  # and are often published first, so only match the `v*` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60ecc0a81ca4f30655434b578a07aa3b0eda9883dbfb1c9747e575639524b1cc"
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
