class Gx < Formula
  desc "Language-agnostic, universal package manager"
  homepage "https://github.com/whyrusleeping/gx"
  url "https://github.com/whyrusleeping/gx/archive/refs/tags/v0.14.3.tar.gz"
  sha256 "2c0b90ddfd3152863f815c35b37e94d027216c6ba1c6653a94b722bf6e2b015d"
  license "MIT"
  head "https://github.com/whyrusleeping/gx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ba836fde5147e2815faefde3e5b1c21602e83d07bd42c5116b96984a4e39163e"
  end

  # project is no longer maintained as people should be
  # expected to use go modules to manage dependencies
  # also see upstream discussion on this, https://github.com/whyrusleeping/gx/issues/247
  deprecate! date: "2024-12-07", because: :unmaintained
  disable! date: "2025-12-07", because: :unmaintained

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "ERROR: no package found in this directory or any above", shell_output("#{bin}/gx deps", 1)
  end
end
