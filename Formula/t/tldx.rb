class Tldx < Formula
  desc "Domain Availability Research Tool"
  homepage "https://brandonyoung.dev/blog/introducing-tldx/"
  url "https://github.com/brandonyoungdev/tldx/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "dde3467c300872e0bfcafe472419d5c1152a30d29731f1e9ee7a9982f85074e8"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "99c7b7f93e7d8460514bc4c7bdfdfa792a82131c23b8baf20005e5cda87397d7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/brandonyoungdev/tldx/cmd.Version=#{version}")
    generate_completions_from_executable(bin/"tldx", shell_parameter_format: :cobra)
  end

  test do
    assert_match "brew.sh is not available", shell_output("#{bin}/tldx brew --tlds sh")

    assert_match version.to_s, shell_output("#{bin}/tldx --version")
  end
end
