class Frizbee < Formula
  desc "Throw a tag at and it comes back with a checksum"
  homepage "https://github.com/stacklok/frizbee"
  url "https://github.com/stacklok/frizbee/archive/refs/tags/v0.1.10.tar.gz"
  sha256 "e52ccdd77b3c6c71bf4b38163df451b550beda279643b071eae9df96b53a455e"
  license "Apache-2.0"
  head "https://github.com/stacklok/frizbee.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9521ad4119b2e3add3d48b7fbd1c852182cd4ddc0f6dbecc98bfa0e42caf33e6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/stacklok/frizbee/internal/cli.CLIVersion=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"frizbee", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frizbee version 2>&1")

    output = shell_output("#{bin}/frizbee actions $(brew --repository)/.github/workflows/tests.yml 2>&1")
    assert_match "Processed: tests.yml", output
  end
end
