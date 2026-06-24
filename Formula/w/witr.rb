class Witr < Formula
  desc "Why is this running?"
  homepage "https://github.com/pranshuparmar/witr"
  url "https://github.com/pranshuparmar/witr/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "af94fe23b01f4b7c672278228efb4a2df622170e0a4ef0e475be337bad11146a"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9894023920a52f3ae62e0c4423e5b47e647196670c07ae69e1f2c430cd5c8bd6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.buildDate=#{time.iso8601}"), "./cmd/witr"
    generate_completions_from_executable(bin/"witr", "completion")
    man1.install "docs/cli/witr.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/witr --version")
    assert_match "no process ancestry found", shell_output("#{bin}/witr --pid 99999999 2>&1", 2)
  end
end
