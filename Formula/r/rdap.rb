class Rdap < Formula
  desc "Command-line client for the Registration Data Access Protocol"
  homepage "https://www.openrdap.org"
  url "https://github.com/openrdap/rdap/archive/refs/tags/v0.9.1.tar.gz"
  sha256 "06a330a9e7d87d89274a0bcedc5852b9f6a4df81baec438fdb6156f49068996d"
  license "MIT"
  head "https://github.com/openrdap/rdap.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "425d0f2b8dd01bb7f5fe0ac51eb6c1aa419d8967bf28cd35c34109e1685e8366"
  end

  depends_on "go" => :build

  conflicts_with "icann-rdap", because: "icann-rdap also ships a rdap binary"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/rdap"
  end

  test do
    # check version
    assert_match "OpenRDAP v#{version}", shell_output("#{bin}/rdap --help 2>&1", 1)

    # no localhost rdap server
    assert_match "No RDAP servers found for", shell_output("#{bin}/rdap -t ip 127.0.0.1 2>&1", 1)

    # check github.com domain on rdap
    output = shell_output("#{bin}/rdap github.com")
    assert_match "Domain Name: GITHUB.COM", output
    assert_match "Nameserver:", output
  end
end
