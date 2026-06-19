class Ucloud < Formula
  desc "Official tool for managing UCloud services"
  homepage "https://www.ucloud.cn"
  url "https://github.com/ucloud/ucloud-cli/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "446d28bfca346d27509b9917c6de75db254e38119171432bb7ad15f105d19316"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7770a9fddd90881e029f8e1e2cc0ea81b7c7bb9d70d2fa64abe4119ec60f690"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "-mod=vendor"
  end

  test do
    system bin/"ucloud", "config", "--project-id", "org-test", "--profile", "default", "--active", "true"
    config_json = (testpath/".ucloud/config.json").read
    assert_match '"project_id":"org-test"', config_json
    assert_match version.to_s, shell_output("#{bin}/ucloud --version")
  end
end
