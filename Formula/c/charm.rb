class Charm < Formula
  desc "Tool for managing Juju Charms"
  homepage "https://github.com/juju/charmstore-client"
  url "https://github.com/juju/charmstore-client/archive/refs/tags/v2.5.2.tar.gz"
  sha256 "3dd52c9a463bc09bedb3a07eb0977711aec77611b9c0d7f40cd366a66aa2ca03"
  license "GPL-3.0-only"
  head "https://github.com/juju/charmstore-client.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6a82bb722aafe20f56c5bc197a4bf305faff1ac477a9b2af98b94000c7c32e3"
  end

  depends_on "breezy" => :build
  depends_on "go" => :build

  def install
    # Charm requires bzr (bazaar vcs) for fetching launchpad.net/lpad Go module.
    ENV["GOVCS"] = "launchpad.net:bzr"
    system "go", "build", *std_go_args, "./cmd/charm"
  end

  test do
    assert_match "show-plan           - show plan details", shell_output("#{bin}/charm 2>&1")

    assert_match "ERROR missing plan url", shell_output("#{bin}/charm show-plan 2>&1", 2)
  end
end
