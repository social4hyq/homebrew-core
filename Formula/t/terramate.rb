class Terramate < Formula
  desc "Managing Terraform stacks with change detections and code generations"
  homepage "https://terramate.io/docs/"
  url "https://github.com/terramate-io/terramate/archive/refs/tags/v0.17.2.tar.gz"
  sha256 "697ddb9f02995e1f2fed07c2eb230c47cc85de5f167fac86f2da02048ed695a2"
  license "MPL-2.0"
  head "https://github.com/terramate-io/terramate.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bfda8f11669e1f6a9b9158af98af996dc4a2c9e2b8a6fa7073c9dde63329189"
  end

  depends_on "go" => :build

  conflicts_with "tenv", because: "both install terramate binary"

  def install
    system "go", "build", *std_go_args(output: bin/"terramate", ldflags: "-s -w"), "./cmd/terramate"
    system "go", "build", *std_go_args(output: bin/"terramate-ls", ldflags: "-s -w"), "./cmd/terramate-ls"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/terramate version")
    assert_match version.to_s, shell_output("#{bin}/terramate-ls -version")
  end
end
