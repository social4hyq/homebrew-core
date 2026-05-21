class Mob < Formula
  desc "Tool for smooth Git handover in mob programming sessions"
  homepage "https://mob.sh"
  url "https://github.com/remotemobprogramming/mob/archive/refs/tags/5.4.2.tar.gz"
  sha256 "be6adc58ffd92cc21fd3fa96bb8eba48f9d3669ed3c1de1df568c37f3625664c"
  license "MIT"
  head "https://github.com/remotemobprogramming/mob.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "107dc1fdccdf0e07660c029ff3fcb39e1d6b09a1f1da61e4ac996161054c94b4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mob version")
    assert_match "MOB_CLI_NAME=\"mob\"", shell_output("#{bin}/mob config")
  end
end
