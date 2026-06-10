class Cosign < Formula
  desc "Container Signing"
  homepage "https://github.com/sigstore/cosign"
  url "https://github.com/sigstore/cosign.git",
      tag:      "v3.1.1",
      revision: "7914231b348c4057891edeb321772aad3ed04fce"
  license "Apache-2.0"
  head "https://github.com/sigstore/cosign.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afcc29e6991cd5b9faa44b962af50644c1b1b51a25fef92a359583480a3e1382"
  end

  depends_on "go" => :build

  def install
    pkg = "sigs.k8s.io/release-utils/version"
    ldflags = %W[
      -s -w
      -X #{pkg}.gitVersion=#{version}
      -X #{pkg}.gitCommit=#{Utils.git_head}
      -X #{pkg}.gitTreeState="clean"
      -X #{pkg}.buildDate=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/cosign"

    generate_completions_from_executable(bin/"cosign", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Private key written to cosign.key",
      pipe_output("#{bin}/cosign generate-key-pair 2>&1", "foo\nfoo\n")
    assert_path_exists testpath/"cosign.pub"

    assert_match version.to_s, shell_output("#{bin}/cosign version 2>&1")
  end
end
