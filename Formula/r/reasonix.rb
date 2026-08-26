class Reasonix < Formula
  desc "Cache-first DeepSeek coding agent for the terminal"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.31.4.tar.gz"
  sha256 "463b3966ff5155ca8ac266d198549038d02b9f45e98a6c04461a62d1887ec14e"
  license "MIT"

  # CLI releases are tagged `v*` while desktop releases are tagged `desktop-v*`
  # and are often published first, so only match the `v*` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e4bc003f047aefc247fc40e7cb797905748bcb304825a413735657a4e07bb7d2"
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
