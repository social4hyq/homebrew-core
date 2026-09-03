class Dnote < Formula
  desc "Simple command-line notebook"
  homepage "https://www.getdnote.com"
  url "https://github.com/dnote/dnote/archive/refs/tags/cli-v0.16.0.tar.gz"
  sha256 "fb63c6099ca441a2027a9e8ae2a3c38376e5c0950bef9e8028b96ca2b8b6427f"
  license "Apache-2.0"
  revision 1
  head "https://github.com/dnote/dnote.git", branch: "master"

  livecheck do
    url :stable
    regex(/^cli[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a62f98f8dfceab61b8ae86721df185e3149089e47a6aff9328abb524576a1a08"
  end

  depends_on "go" => :build

  patch do
    file "Patches/dnote/0001-add-getenv-home-fallback.patch"
  end

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    ldflags = "-s -w -X main.versionTag=#{version} -X main.apiEndpoint=http://localhost:3001/api"
    system "go", "build", *std_go_args(ldflags:, tags: "fts5"), "./pkg/cli"
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath
    ENV["XDG_DATA_HOME"] = testpath
    ENV["XDG_CACHE_HOME"] = testpath

    assert_match version.to_s, shell_output("#{bin}/dnote version")

    desc = "Check disk usage with df -h"
    system bin/"dnote", "add", "linux", "-c", desc
    assert_match desc, shell_output("#{bin}/dnote view linux")
    assert_match desc, shell_output("#{bin}/dnote find 'disk usage'")
  end
end
