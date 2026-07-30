class K0sctl < Formula
  desc "Bootstrapping and management tool for k0s clusters"
  homepage "https://github.com/k0sproject/k0sctl"
  url "https://github.com/k0sproject/k0sctl/archive/refs/tags/v0.32.2.tar.gz"
  sha256 "0df9d24cd7a04b039c31ed641983c41a8b23cd26e17288c9cda099f4f271ba54"
  license "Apache-2.0"
  head "https://github.com/k0sproject/k0sctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4accbd4c98e1d7801df4770850fa5e15b24be7539aa990cc687b3e21711df75d"
  end

  depends_on "go" => :build

  def install
    inreplace "version/version.go", "Version = versioninfo.Version", "Version = \"v#{version}\"" if build.stable?

    ldflags = %W[
      -s -w
      -X github.com/k0sproject/k0sctl/version.Environment=production
      -X github.com/carlmjohnson/versioninfo.Revision=#{tap.user}
      -X github.com/carlmjohnson/versioninfo.Version=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"k0sctl", "completion", "--shell")
  end

  test do
    assert_match "version: v#{version}", shell_output("#{bin}/k0sctl version")

    output = shell_output("#{bin}/k0sctl init")
    assert_match "apiVersion: k0sctl.k0sproject.io/v1beta1", output

    output = shell_output("#{bin}/k0sctl init --cluster-name brew-test")
    assert_match "name: brew-test", output
  end
end
