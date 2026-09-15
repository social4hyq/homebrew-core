class Upterm < Formula
  desc "Instant terminal sharing"
  homepage "https://github.com/owenthereal/upterm"
  url "https://github.com/owenthereal/upterm/archive/refs/tags/v0.28.0.tar.gz"
  sha256 "818b7bc53adb51578f81b16ff293034232f66d51f07feb7a1371b2c4d0a923e1"
  license "Apache-2.0"
  head "https://github.com/owenthereal/upterm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c52753c7ba7a5b1b1ac6733c86c0ac3d92d611348eb8c7448e3424cec8f8e8c"
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
