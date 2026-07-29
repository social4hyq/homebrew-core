class Gitsign < Formula
  desc "Keyless Git signing using Sigstore"
  homepage "https://github.com/sigstore/gitsign"
  url "https://github.com/sigstore/gitsign/archive/refs/tags/v0.17.1.tar.gz"
  sha256 "0325dc76ec9e2d8d81d96aaeb6dfde0317f6cdfc60710fbab9eb636648388085"
  license "Apache-2.0"
  head "https://github.com/sigstore/gitsign.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a06bb1bd308570a40e380c2d21c4374a12ac894c21e2ff4df9bfc78e39fe1437"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/sigstore/gitsign/pkg/version.gitVersion=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
    system "go", "build", *std_go_args(ldflags:, output: bin/"gitsign-credential-cache"),
      "./cmd/gitsign-credential-cache"

    generate_completions_from_executable(bin/"gitsign", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gitsign --version")

    system "git", "clone", "https://github.com/sigstore/gitsign.git"
    cd testpath/"gitsign" do
      require "pty"
      stdout, _stdin, _pid = PTY.spawn("#{bin}/gitsign attest")
      assert_match "Generating ephemeral keys...", stdout.readline
    end
  end
end
