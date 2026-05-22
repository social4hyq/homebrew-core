class Falcoctl < Formula
  desc "CLI tool for working with Falco and its ecosystem components"
  homepage "https://github.com/falcosecurity/falcoctl"
  url "https://github.com/falcosecurity/falcoctl/archive/refs/tags/v0.12.2.tar.gz"
  sha256 "05290a97ac6ac886fc4b34d157d533de37d5a1031f81cf4e6eb1f056c4015f49"
  license "Apache-2.0"
  head "https://github.com/falcosecurity/falcoctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5fc39e2dd0331c93cd5bc9e8630958074f2abc756147c746da460beb51235867"
  end

  depends_on "go" => :build

  def install
    pkg = "github.com/falcosecurity/falcoctl/cmd/version"
    ldflags = %W[
      -s -w
      -X #{pkg}.buildDate=#{time.iso8601}
      -X #{pkg}.gitCommit=#{tap.user}
      -X #{pkg}.semVersion=#{version}
    ]

    system "go", "build", *std_go_args(ldflags:), "."

    generate_completions_from_executable(bin/"falcoctl", shell_parameter_format: :cobra)
  end

  test do
    system bin/"falcoctl", "tls", "install"
    assert_path_exists testpath/"ca.crt"
    assert_path_exists testpath/"client.crt"

    assert_match version.to_s, shell_output("#{bin}/falcoctl version")
  end
end
