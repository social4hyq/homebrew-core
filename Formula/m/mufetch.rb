class Mufetch < Formula
  desc "Neofetch-style music cli"
  homepage "https://github.com/ashish0kumar/mufetch"
  url "https://github.com/ashish0kumar/mufetch/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "c6cba3e87e21809c640e540d396d3f72bdaa4fd42fdb79de43ada7cd6a589f0e"
  license "MIT"
  head "https://github.com/ashish0kumar/mufetch.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab69473759d16440ec493da33146162fe0d0b9bd1390a4cc31e310b9a44eb047"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/ashish0kumar/mufetch/cmd.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mufetch --version")
    output = shell_output("#{bin}/mufetch search 'Bohemian Rhapsody' 2>&1", 1)
    assert_match "No Spotify credentials found", output
  end
end
