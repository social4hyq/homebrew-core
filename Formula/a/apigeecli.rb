class Apigeecli < Formula
  desc "Apigee management API command-line interface"
  homepage "https://cloud.google.com/apigee/docs"
  url "https://github.com/apigee/apigeecli/archive/refs/tags/v2.17.0.tar.gz"
  sha256 "9b9fc5f70732b08d21165bbd2c39cbb88f73c700480a8fda8bc52c6b2da9cff0"
  license "Apache-2.0"
  head "https://github.com/apigee/apigeecli.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fef6f7659e13bc26030e1be57ac335ab51dd7c206b66afea1633c43abe7c1e55"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{version}
      -X main.date=#{time.iso8601}
    ]
    gcflags = 'all="-l"'
    system "go", "build", *std_go_args(ldflags:, gcflags:), "./cmd/apigeecli"

    generate_completions_from_executable(bin/"apigeecli", shell_parameter_format: :cobra)
  end

  test do
    assert_match "apigeecli version #{version}", shell_output("#{bin}/apigeecli --version")

    ENV["APIGEECLI_DRYRUN"] = "true"
    apigeecli_apis_list = "#{bin}/apigeecli apis list --org=homebrew-test --token='homebrew-test' 2>&1"
    assert_match "Dry run mode enabled! unset APIGEECLI_DRYRUN to disable dry run", shell_output(apigeecli_apis_list)
  end
end
