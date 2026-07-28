class Zns < Formula
  desc "CLI tool for querying DNS records with readable, colored output"
  homepage "https://github.com/znscli/zns"
  url "https://github.com/znscli/zns/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "ca22ea3cdf0e46f79c64e5a7d442e4242d5d27acd6d4c031f677aabeac0c7b14"
  license "MIT"
  head "https://github.com/znscli/zns.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be514138b6bf567cacabfa4825b14f8740a104e815290b4d6c0c08989102baaa"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/znscli/zns/cmd.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zns --version")
    assert_match "hera.ns.cloudflare.com.", shell_output("#{bin}/zns example.com -q NS --server 1.1.1.1")
  end
end
