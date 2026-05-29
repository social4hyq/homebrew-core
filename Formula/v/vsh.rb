class Vsh < Formula
  desc "HashiCorp Vault interactive shell"
  homepage "https://github.com/fishi0x01/vsh"
  url "https://github.com/fishi0x01/vsh/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "567ced47700cf36e0a542867e2b92f816757b62e149cc62002dc561ab2312cfd"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9066a8d26d900f079229c680912b36e5ad4b5dc6c90246e0083d5efd8c7e002"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.vshVersion=v#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    version_output = shell_output("#{bin}/vsh --version")
    assert_match version.to_s, version_output
    error_output = shell_output("#{bin}/vsh -c ls 2>&1", 1)
    assert_match "Error initializing vault client | Is VAULT_ADDR properly set?", error_output
  end
end
