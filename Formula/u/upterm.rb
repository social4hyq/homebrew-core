class Upterm < Formula
  desc "Instant terminal sharing"
  homepage "https://github.com/owenthereal/upterm"
  url "https://github.com/owenthereal/upterm/archive/refs/tags/v0.26.0.tar.gz"
  sha256 "2eee37b11631e7ecf2a51c94d7a5051fcdf5beebf0fd69f50c9272fb0252de55"
  license "Apache-2.0"
  head "https://github.com/owenthereal/upterm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2e88f98b2e244e8066bc01921c6e1d600bd9aded9621d8c5d4747fdafd2dfa7"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/owenthereal/upterm/internal/version.Version=#{version}
      -X github.com/owenthereal/upterm/internal/version.Date=#{time.iso8601}
    ]

    %w[upterm uptermd].each do |cmd|
      system "go", "build", *std_go_args(output: bin/cmd, ldflags:), "./cmd/#{cmd}"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/upterm version")
    assert_match version.to_s, shell_output("#{bin}/uptermd version")

    output = shell_output("#{bin}/upterm config view")
    assert_match "# Upterm Configuration File", output
    assert_match "server: ssh://uptermd.upterm.dev:22", output
  end
end
