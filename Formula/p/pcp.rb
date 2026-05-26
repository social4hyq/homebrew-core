class Pcp < Formula
  desc "Command-line peer-to-peer data transfer tool based on libp2p"
  homepage "https://github.com/dennis-tra/pcp"
  url "https://github.com/dennis-tra/pcp.git",
      tag:      "v0.4.0",
      revision: "7f638fe42f6dbd17e5bf5a7be5854220e2858eb2"
  license "Apache-2.0"
  head "https://github.com/dennis-tra/pcp.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "814dca45bb95cd8f1de0d5861b6c0c5056062eca77c6737ccb766724e4e91889"
  end

  deprecate! date: "2025-05-17", because: :repo_archived
  disable! date: "2026-05-17", because: :repo_archived

  depends_on "go" => :build

  def install
    # TODO: remove `-checklinkname=0` workaround when fixed
    # https://github.com/dennis-tra/pcp/issues/30
    ldflags = %W[
      -s -w
      -X main.RawVersion=#{version}
      -X main.ShortCommit=#{Utils.git_short_head(length: 7)}
      -checklinkname=0
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/pcp"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pcp --version")
    expected = "error: failed to initialize node: could not find all words in a single wordlist"
    assert_equal expected, shell_output("#{bin}/pcp receive words-that-dont-exist 2>&1", 1).chomp
  end
end
