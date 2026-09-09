class Gnmic < Formula
  desc "GNMI CLI client and collector"
  homepage "https://gnmic.openconfig.net"
  url "https://github.com/openconfig/gnmic/archive/refs/tags/v0.48.0.tar.gz"
  sha256 "444aad2dd219a39c0dba35f8537572b1c5fdc5e847f25ba00d2f0379293a3921"
  license "Apache-2.0"
  head "https://github.com/openconfig/gnmic.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9038b17a3e8582bfafacd7a0a98150e376a836925b2c7c6d975fb32a71faa3e"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/openconfig/gnmic/pkg/version.Version=#{version}
      -X github.com/openconfig/gnmic/pkg/version.Commit=#{tap.user}
      -X github.com/openconfig/gnmic/pkg/version.Date=#{time.iso8601}
      -X github.com/openconfig/gnmic/pkg/version.GitURL=https://github.com/openconfig/gnmic
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"gnmic", "completion")
  end

  test do
    connection_output = shell_output("#{bin}/gnmic -u gnmi -p dummy --skip-verify \
                                     --timeout 1s -a 127.0.0.1:0 capabilities 2>&1", 1)
    assert_match "target \"127.0.0.1:0\", capabilities request failed", connection_output

    assert_match version.to_s, shell_output("#{bin}/gnmic version")
  end
end
