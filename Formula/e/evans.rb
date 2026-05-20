class Evans < Formula
  desc "More expressive universal gRPC client"
  homepage "https://github.com/ktr0731/evans"
  url "https://github.com/ktr0731/evans/archive/refs/tags/v0.10.11.tar.gz"
  sha256 "980177e9a7a88e2d9d927acb8171466c40dcef2db832ee4b638ba512d50cce37"
  license "MIT"
  head "https://github.com/ktr0731/evans.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "501c760ca5845a9a79faccd660dcfadd4c1a8914631cfcff15cac3c94411869f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/evans --version")

    output = shell_output("#{bin}/evans -r cli list 2>&1", 1)
    assert_match "failed to list packages by gRPC reflection", output
  end
end
