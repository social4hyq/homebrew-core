class Labctl < Formula
  desc "CLI tool for interacting with iximiuz labs and playgrounds"
  homepage "https://github.com/iximiuz/labctl"
  url "https://github.com/iximiuz/labctl/archive/refs/tags/v0.1.112.tar.gz"
  sha256 "3579988a92e6d75ca94c4ac4a58b92a791d0dfba87e146f5a32cdd7bb0c2a170"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f915c2591bc8d2c91c08cc12a0c3284ecb3f4c3b3295730d1c7747350b53d483"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.date=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/labctl --version")

    assert_match "Not logged in.", shell_output("#{bin}/labctl auth whoami 2>&1")
    assert_match "authentication required.", shell_output("#{bin}/labctl playground list 2>&1", 1)
  end
end
