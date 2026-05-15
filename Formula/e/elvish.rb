class Elvish < Formula
  desc "Friendly and expressive shell"
  homepage "https://elv.sh/"
  url "https://github.com/elves/elvish/archive/refs/tags/v0.21.0.tar.gz"
  sha256 "3a4b93c3c99fe2f9847de35d64be24e2d4b9c12d429cd9831b4571993a66bb7a"
  license "BSD-2-Clause"
  head "https://github.com/elves/elvish.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93d826493aa4489e570b03db745fd4a16d81d90a0b9066ee5ae4acd9b14893cc"
  end

  depends_on "go" => :build

  def install
    system "go", "build",
      *std_go_args(ldflags: "-s -w -X src.elv.sh/pkg/buildinfo.VersionSuffix="), "./cmd/elvish"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/elvish -version").chomp
    assert_match "hello", shell_output("#{bin}/elvish -c 'echo hello'")
  end
end
