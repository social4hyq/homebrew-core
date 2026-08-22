class Reasonix < Formula
  desc "Cache-first DeepSeek coding agent for the terminal"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.31.2.tar.gz"
  sha256 "937710c4242f9cedf434f76332324a3baf504d8a2575d52469d5183c4e303952"
  license "MIT"

  # CLI releases are tagged `v*` while desktop releases are tagged `desktop-v*`
  # and are often published first, so only match the `v*` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cff429a0ca7ef2777c010e282db045367c8dff98ee2bdd055cf7f3b357087ee5"
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
