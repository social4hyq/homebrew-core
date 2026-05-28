class Yatas < Formula
  desc "Tool to audit AWS/GCP infrastructure for misconfiguration or security issues"
  homepage "https://github.com/padok-team/yatas"
  url "https://github.com/padok-team/yatas/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "d4ecca0180fe9c5447cc13ce9a2b2bdab4a5b977060f5e89b87e9f4ca71d5857"
  license "Apache-2.0"
  head "https://github.com/padok-team/yatas.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1bfd7af440f23f462b90a6711042b09b501efe2764765c16db8c9f2b58f5fbe"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    system bin/"yatas", "--init"
    output = shell_output("#{bin}/yatas --install 2>&1")
    assert_match "failed to refresh cached credentials, no EC2 IMDS role found", output
  end
end
