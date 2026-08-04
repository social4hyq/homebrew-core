class Ipget < Formula
  desc "Retrieve files over IPFS and save them locally"
  homepage "https://github.com/ipfs/ipget/"
  url "https://github.com/ipfs/ipget/archive/refs/tags/v0.13.2.tar.gz"
  sha256 "e30a9f84633562b4c4d262b4c027260d43a6dcb47630215c7221dcc8066e8816"
  license "MIT"
  head "https://github.com/ipfs/ipget.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "231e1163c39ddfc4b6f6f19ec33eefbeb7d2ff6cfe675770450c0a6a0eed66b0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    # Make sure correct version is reported
    assert_match version.to_s, shell_output("#{bin}/ipget --version")

    # An example content identifier (CID) used in IPFS docs:
    # https://docs.ipfs.tech/concepts/content-addressing/
    cid = "bafybeihkoviema7g3gxyt6la7vd5ho32ictqbilu3wnlo3rs7ewhnp7lly"
    system bin/"ipget", "ipfs://#{cid}/"
    assert_match "JPEG image data", shell_output("file #{cid}")
  end
end
