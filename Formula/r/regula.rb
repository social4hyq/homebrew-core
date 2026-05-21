class Regula < Formula
  desc "Checks infrastructure as code templates using Open Policy Agent/Rego"
  homepage "https://regula.dev/"
  url "https://github.com/fugue/regula.git",
      tag:      "v3.2.1",
      revision: "fed1e441b187504a5928e2999a6210b88279139c"
  license "Apache-2.0"
  head "https://github.com/fugue/regula.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bd54d9f9f2544ec6cdfaade36d2e034316d5f49f91c94e27569fd80ba74ecfda"
  end

  deprecate! date: "2025-04-27", because: :repo_archived, replacement_formula: "policy-engine"
  disable! date: "2026-04-27", because: :repo_archived, replacement_formula: "policy-engine"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/fugue/regula/v3/pkg/version.Version=#{version}
      -X github.com/fugue/regula/v3/pkg/version.GitCommit=#{Utils.git_short_head}
    ]

    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"regula", shell_parameter_format: :cobra)
  end

  test do
    (testpath/"infra/test.tf").write <<~HCL
      resource "aws_s3_bucket" "foo-bucket" {
        region        = "us-east-1"
        bucket        = "test"
        acl           = "public-read"
        force_destroy = true

        versioning {
          enabled = true
        }
      }
    HCL

    assert_match "Found 10 problems", shell_output("#{bin}/regula run infra", 1)

    assert_match version.to_s, shell_output("#{bin}/regula version")
  end
end
