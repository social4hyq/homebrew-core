class Akamai < Formula
  desc "CLI toolkit for working with Akamai's APIs"
  homepage "https://github.com/akamai/cli"
  url "https://github.com/akamai/cli/archive/refs/tags/v2.0.4.tar.gz"
  sha256 "5f0d5217e3434fc57bfc821519379a1705ed749ae754853ea1d40ff65e21eb69"
  license "Apache-2.0"
  head "https://github.com/akamai/cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a05dd17f4d0c3df731485f5ed496d4eb160ae0ff50a77fc74ddbeb4a6709141"
  end

  depends_on "go" => [:build, :test]

  def install
    tags = %w[
      noautoupgrade
      nofirstrun
    ]
    system "go", "build", *std_go_args(ldflags: "-s -w", tags:), "./cli"
  end

  test do
    assert_match "diagnostics", shell_output("#{bin}/akamai install diagnostics")
    system bin/"akamai", "uninstall", "diagnostics"
  end
end
