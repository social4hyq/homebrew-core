class Goproxy < Formula
  desc "Global proxy for Go modules"
  homepage "https://goproxy.io/"
  url "https://github.com/goproxyio/goproxy/archive/refs/tags/v2.0.7.tar.gz"
  sha256 "d87f3928467520f8d6b0ba8adcbf5957dc6eb2dc9936249edd6568ceb01a71ca"
  license "MIT"
  head "https://github.com/goproxyio/goproxy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ee0fddf1d2bc0c23ce0d0f3f683d302bf18fa61ba4f53bf8471b126f1aa7096b"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    ENV["GOPATH"] = testpath.to_s
    bind_address = "127.0.0.1:#{free_port}"
    begin
      server = IO.popen("#{bin}/goproxy -proxy=https://goproxy.io -listen=#{bind_address}", err: [:child, :out])
      sleep 1
      sleep 2 if OS.mac? && Hardware::CPU.intel?
      ENV["GOPROXY"] = "http://#{bind_address}"
      system "go", "install", "golang.org/x/tools/cmd/goimports@latest"
    ensure
      Process.kill("SIGINT", server.pid)
    end
    assert_match "200 /golang.org/x/tools/", server.read
  end
end
