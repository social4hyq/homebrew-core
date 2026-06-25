class Vet < Formula
  desc "Policy driven vetting of open source dependencies"
  homepage "https://safedep.io/"
  url "https://github.com/safedep/vet/archive/refs/tags/v1.17.5.tar.gz"
  sha256 "bf53ea353e117c45ac48c786a73f8d24b660c6a1db1e44083a434c66f1318bb3"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38dcc8461707c749e2595ca3e03ffe48fd2e241b66dcdbbbf04968b4e1100040"
  end

  depends_on "go"

  def install
    ENV["CGO_ENABLED"] = "1"
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"vet", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vet version 2>&1")

    output = shell_output("#{bin}/vet scan parsers 2>&1")
    assert_match "Available Lockfile Parsers", output
  end
end
