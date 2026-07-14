class Ucloud < Formula
  desc "Official tool for managing UCloud services"
  homepage "https://www.ucloud.cn"
  url "https://github.com/ucloud/ucloud-cli/archive/refs/tags/v0.3.7.tar.gz"
  sha256 "1e2c0d418ef1f916f1c7659fff1de298ebfdd28f6f343cd40d31a37c57366b2a"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a535bbba33fa040892a80ebdaf21e8a4905ae1c0549ba5b04aa258d1dd53366"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/ucloud/ucloud-cli/cmd/internal/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    system bin/"ucloud", "config", "--project-id", "org-test", "--profile", "default", "--active", "true"
    config_json = (testpath/".ucloud/config.json").read
    assert_match '"project_id":"org-test"', config_json
    assert_match version.to_s, shell_output("#{bin}/ucloud --version")
  end
end
