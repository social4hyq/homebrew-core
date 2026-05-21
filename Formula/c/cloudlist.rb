class Cloudlist < Formula
  desc "Tool for listing assets from multiple cloud providers"
  homepage "https://github.com/projectdiscovery/cloudlist"
  url "https://github.com/projectdiscovery/cloudlist/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "1a165e5dc6dd1f4950517efb569e1527a9d8462af2367917660711ebbdf5e5a6"
  license "MIT"
  head "https://github.com/projectdiscovery/cloudlist.git", branch: "dev"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6fa7f098c09ea6a3c8f8c3d790212dc30e8d1b5beb5b4d44ef77f98fc53c3b03"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/cloudlist"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cloudlist -version 2>&1")

    output = shell_output bin/"cloudlist", 1
    assert_match output, "invalid provider configuration file provided"
  end
end
