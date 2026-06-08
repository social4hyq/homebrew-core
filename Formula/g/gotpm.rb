class Gotpm < Formula
  desc "CLI for using TPM 2.0"
  homepage "https://github.com/google/go-tpm-tools"
  url "https://github.com/google/go-tpm-tools/archive/refs/tags/v0.4.9.tar.gz"
  sha256 "a2eb3739afa65b60c351550c6c0541f17c5af6a22837da3690fcd6e44ef354bf"
  license "Apache-2.0"
  head "https://github.com/google/go-tpm-tools.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "864d081ef6fb6b15331a7b8f63d787b315c1eb4115f6c929ed26a99b46bfd682"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/gotpm"
    generate_completions_from_executable(bin/"gotpm", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/gotpm attest 2>&1", 1)
    assert_match "Error: connecting to TPM: stat /dev/tpm0: no such file or directory", output
  end
end
