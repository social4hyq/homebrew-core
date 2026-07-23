class Doctl < Formula
  desc "Command-line tool for DigitalOcean"
  homepage "https://github.com/digitalocean/doctl"
  url "https://github.com/digitalocean/doctl/archive/refs/tags/v1.164.0.tar.gz"
  sha256 "83ad66a22c3cb8193b36d1929fc9c980e3d2e796bbc63c841ade90d35f7cefce"
  license "Apache-2.0"
  head "https://github.com/digitalocean/doctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8233dd21afb4d3fb0c1a9ce7feee7837eddde806416b700d3d68dfb4a6becb20"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/digitalocean/doctl.Major=#{version.major}
      -X github.com/digitalocean/doctl.Minor=#{version.minor}
      -X github.com/digitalocean/doctl.Patch=#{version.patch}
      -X github.com/digitalocean/doctl.Label=release
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/doctl"

    generate_completions_from_executable(bin/"doctl", shell_parameter_format: :cobra)
  end

  test do
    assert_match "doctl version #{version}-release", shell_output("#{bin}/doctl version")
  end
end
