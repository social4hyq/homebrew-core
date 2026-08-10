class Dnspyre < Formula
  desc "CLI tool for a high QPS DNS benchmark"
  homepage "https://tantalor93.github.io/dnspyre/"
  url "https://github.com/Tantalor93/dnspyre/archive/refs/tags/v3.12.0.tar.gz"
  sha256 "a7f227edcb297659aad5d4f235e6aa82c8990e004d69fb69b6c81d2371dc46d5"
  license "MIT"
  head "https://github.com/Tantalor93/dnspyre.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a1de084a7708f381d5eaf66458f52aedc9678b4c210542b8065f9c4f34d5030"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/tantalor93/dnspyre/v#{version.major}/cmd.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dnspyre --version 2>&1")

    output = shell_output("#{bin}/dnspyre example.com")
    assert_match "Using 1 hostnames", output.gsub(/\e\[[0-9;]*m/, "")
  end
end
