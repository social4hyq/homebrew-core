class Gitmux < Formula
  desc "Git status in tmux status bar"
  homepage "https://github.com/arl/gitmux"
  url "https://github.com/arl/gitmux/archive/refs/tags/v0.11.5.tar.gz"
  sha256 "c6a01faa5372a8c4ab24bc3a2c9665a9f430c45c79b175c1510388433637ca72"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "06910cd93b9607855a9fd0c33f94ad732fe60ffce55842d424d7f840ccd1c548"
  end

  depends_on "go" => :build
  depends_on "tmux"

  def install
    ldflags = "-s -w -X main.version=#{version}"

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gitmux -V")

    system "git", "init", "--initial-branch=gitmux"

    # `gitmux` breaks our git shim by clearing the environment.
    ENV.remove "PATH", "#{HOMEBREW_SHIMS_PATH}/shared:"
    assert_match '"LocalBranch": "gitmux"', shell_output("#{bin}/gitmux -dbg")
  end
end
