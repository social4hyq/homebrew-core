class Notify < Formula
  desc "Stream the output of any CLI and publish it to a variety of supported platforms"
  homepage "https://docs.projectdiscovery.io/tools/notify/overview"
  url "https://github.com/projectdiscovery/notify/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "ec9f1e6c48f975b58d30162071d954db0cd771ea3f5dc7168f5ecdc73658c0ad"
  license "MIT"
  head "https://github.com/projectdiscovery/notify.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0925d33c0982bdfee5319ab2ce57bf41737a64f6fd947a2e5d564a822275ca4e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/notify"
  end

  test do
    assert_match "Current Version: #{version}", shell_output("#{bin}/notify -disable-update-check -version 2>&1")
    output = shell_output("#{bin}/notify -disable-update-check -config \"#{testpath}/non_existent\" 2>&1", 1)
    assert_match "Could not read config", output
  end
end
