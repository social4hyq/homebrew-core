class Pixie < Formula
  desc "Observability tool for Kubernetes applications"
  homepage "https://px.dev/"
  url "https://github.com/pixie-io/pixie.git",
      tag:      "release/cli/v0.8.8",
      revision: "042e35639f16d32fced41939c5fbc5085e1272ff"
  license "Apache-2.0"
  head "https://github.com/pixie-io/pixie.git", branch: "main"

  livecheck do
    url :stable
    regex(%r{^release/cli/v?(\d+(?:\.\d+)+)$}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc95742ae8b2844f153e0417d3f82f47eaae5ad52fb5f8685d09c88cb1b07fd5"
  end

  depends_on "go" => :build

  conflicts_with "px", because: "both install `px` binaries"

  def install
    semver = build.head? ? "0.0.0-dev" : version
    ldflags = %W[
      -s -w
      -X px.dev/pixie/src/shared/goversion.buildSCMRevision=#{Utils.git_short_head}
      -X px.dev/pixie/src/shared/goversion.buildSCMStatus=Distribution
      -X px.dev/pixie/src/shared/goversion.buildSemver=#{semver}
      -X px.dev/pixie/src/shared/goversion.buildTimeStamp=#{time.to_i}
      -X px.dev/pixie/src/shared/goversion.buildNumber=#{revision + bottle&.rebuild.to_i + 1}
      -X px.dev/pixie/src/shared/goversion.builtBy=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"px"), "./src/pixie_cli"

    generate_completions_from_executable(bin/"px", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/px version")
    assert_match tap.user.to_s, shell_output("#{bin}/px version")
    assert_match "You must be logged in to perform this operation.", shell_output("#{bin}/px deploy 2>&1", 1)
  end
end
