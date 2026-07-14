class Opkssh < Formula
  desc "Enables SSH to be used with OpenID Connect"
  homepage "https://eprint.iacr.org/2023/296"
  url "https://github.com/openpubkey/opkssh/archive/refs/tags/v0.16.0.tar.gz"
  sha256 "b7c326b24d6fe97056d459f2d5ef7eafb25890b70279537746a368467fe2dc3b"
  license "Apache-2.0"
  head "https://github.com/openpubkey/opkssh.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0eb7942b881990dd690f2f146d3e083cdcb12f5e7f77b8a099b6ccf0f51015dd"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opkssh --version")

    output = shell_output("#{bin}/opkssh add brew brew brew 2>&1", 1)
    assert_match "Failed to add to policy", output
  end
end
