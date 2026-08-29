class Reasonix < Formula
  desc "Cache-first DeepSeek coding agent for the terminal"
  homepage "https://github.com/esengine/DeepSeek-Reasonix"
  url "https://github.com/esengine/DeepSeek-Reasonix/archive/refs/tags/v1.32.1.tar.gz"
  sha256 "9ad37904398bce226daeee5ea24ff0e3cda506db1afc111d3f035428b9f7fdf8"
  license "MIT"

  # CLI releases are tagged `v*` while desktop releases are tagged `desktop-v*`
  # and are often published first, so only match the `v*` tags.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/\Av(\d+(?:\.\d+)+)\z/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fee1b2344b782c5eb63fff2a9c442a8c223ce2199e51ddae9f72f0dad6d3efc5"
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
