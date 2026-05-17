class Bombardier < Formula
  desc "Cross-platform HTTP benchmarking tool"
  homepage "https://github.com/codesenberg/bombardier"
  url "https://github.com/codesenberg/bombardier/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "472b14b1c3be26a5f6254f6b7c24f86c9b756544baa5ca28cbfad06aacf7f4ac"
  license "MIT"
  head "https://github.com/codesenberg/bombardier.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a987a20b1b21ff926a285793d5dc6ec837a980d6f3e5970796ea08a657ea5eff"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bombardier --version 2>&1")

    url = "https://example.com"
    output = shell_output("#{bin}/bombardier -c 1 -n 1 #{url}")
    assert_match "Bombarding #{url} with 1 request(s) using 1 connection(s)", output
  end
end
