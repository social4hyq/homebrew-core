class OpenscaCli < Formula
  desc "OpenSCA is a supply-chain security tool for security researchers and developers"
  homepage "https://opensca.xmirror.cn"
  url "https://github.com/XmirrorSecurity/OpenSCA-cli/archive/refs/tags/v3.0.11.tar.gz"
  sha256 "91a4951baf951580ef8eeda6096521026193c177f2ed4082c08a9d74442fd7fa"
  license "Apache-2.0"
  head "https://github.com/XmirrorSecurity/OpenSCA-cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1a5ffb557d3db49133c56d2b4168f48ae36a022ca7fe3885f53c981e2be40d1"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X 'main.version=#{version}'"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    system bin/"opensca-cli", "-path", testpath
    assert_path_exists testpath/"opensca.log"
    assert_match version.to_s, shell_output("#{bin}/opensca-cli -version")
  end
end
