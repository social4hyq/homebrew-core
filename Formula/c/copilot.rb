class Copilot < Formula
  desc "CLI tool for Amazon ECS and AWS Fargate"
  homepage "https://aws.github.io/copilot-cli/"
  url "https://github.com/aws/copilot-cli/archive/refs/tags/v1.34.1.tar.gz"
  sha256 "42f37960360063a9a277d40d9e1c0b284bc49a12dbf996696551154737d94475"
  license "Apache-2.0"
  head "https://github.com/aws/copilot-cli.git", branch: "mainline"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2e804bcff76711cd3c893741ea52f0bd20e042e5d667738e5d36e181809e282"
  end

  depends_on "go" => :build
  depends_on "node" => :build

  def install
    ENV.deparallelize
    system "make", "VERSION=#{version}"
    bin.install "bin/local/copilot"
    generate_completions_from_executable(bin/"copilot", "completion")
  end

  test do
    ENV["AWS_REGION"] = ENV["AWS_SECRET_ACCESS_KEY"] = "test"
    ENV["AWS_ACCESS_KEY_ID"] = "eu-west-1"
    begin
      _, stdout, wait_thr = Open3.popen2("#{bin}/copilot init 2>&1")
      assert_match "Note: It's best to run this command in the root of your Git repository", stdout.gets("\n")
    ensure
      Process.kill 9, wait_thr.pid
    end

    output = shell_output("#{bin}/copilot pipeline init 2>&1", 1)
    assert_match "Run `copilot app init` to create an application", output
  end
end
