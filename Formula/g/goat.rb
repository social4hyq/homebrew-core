class Goat < Formula
  desc "General purpose AT Protocol CLI in Go"
  homepage "https://github.com/bluesky-social/goat"
  url "https://github.com/bluesky-social/goat.git",
      tag:      "v0.2.3",
      revision: "d064a46ac03be902dca493b6b2ce1659e8619c3a"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9191f52c6005bab6b1993d8a3e094f749ece381f27aa96999dcfdec26af966ad"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goat --version")

    output = shell_output("#{bin}/goat get at://atproto.com/app.bsky.actor.profile/self")
    assert_match "Social networking technology created by Bluesky.", output
    assert_match "\"displayName\": \"AT Protocol Developers\"", output
  end
end
