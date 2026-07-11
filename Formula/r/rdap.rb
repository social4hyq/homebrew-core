class Rdap < Formula
  desc "Command-line client for the Registration Data Access Protocol"
  homepage "https://www.openrdap.org"
  url "https://github.com/openrdap/rdap/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "19a6b1fe6c3335fa8bb48fb4c33ce56082e0ffdd24dd649745793613ab6c85cb"
  license "MIT"
  head "https://github.com/openrdap/rdap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "425d0f2b8dd01bb7f5fe0ac51eb6c1aa419d8967bf28cd35c34109e1685e8366"
  end

  depends_on "go" => :build

  conflicts_with "icann-rdap", because: "icann-rdap also ships a rdap binary"

  def install
    ldflags = %W[
      -s -w
      -X github.com/openrdap/rdap.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/rdap"
  end

  test do
    # check version
    assert_match version.to_s, shell_output("#{bin}/rdap --help 2>&1", 1)

    # no localhost rdap server
    assert_match "No RDAP servers found for", shell_output("#{bin}/rdap -t ip 127.0.0.1 2>&1", 1)

    # check github.com domain on rdap
    output = shell_output("#{bin}/rdap github.com")
    assert_match "Domain Name: GITHUB.COM", output
    assert_match "Nameserver:", output
  end
end
