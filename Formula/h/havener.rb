class Havener < Formula
  desc "Swiss army knife for Kubernetes tasks"
  homepage "https://github.com/homeport/havener"
  url "https://github.com/homeport/havener/archive/refs/tags/v2.2.7.tar.gz"
  sha256 "f923cd42bb4ded5535aa089037bc285110b2bc335ae108553e50ac8bddeafff0"
  license "MIT"
  head "https://github.com/homeport/havener.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "322fb2f8d22c335063298e5004830f0f211d31d587e18eb674a8fb4960b94974"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/homeport/havener/internal/cmd.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/havener"

    generate_completions_from_executable(bin/"havener", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/havener version")

    assert_match "unable to get access to cluster", shell_output("#{bin}/havener events 2>&1", 1)
  end
end
