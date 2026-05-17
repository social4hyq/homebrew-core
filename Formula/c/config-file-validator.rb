class ConfigFileValidator < Formula
  desc "CLI tool to validate different configuration file types"
  homepage "https://boeing.github.io/config-file-validator/"
  url "https://github.com/Boeing/config-file-validator/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "b1e2082d97f15446cbbd5de47c4614994aba862061acb89f2d49499d2838bfcb"
  license "Apache-2.0"
  head "https://github.com/Boeing/config-file-validator.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00330ad716fcdb48d270789ea041d385da829fbae0441a72915b7c59758d0b3b"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/Boeing/config-file-validator/v2.version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"validator"), "./cmd/validator"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/validator -version")

    test_file = testpath/"test.json"
    test_file.write('{"valid": "json"}')
    assert_match "✓ #{test_file}", shell_output("#{bin}/validator #{test_file}")
  end
end
