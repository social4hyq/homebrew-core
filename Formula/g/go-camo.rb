class GoCamo < Formula
  desc "Secure image proxy server"
  homepage "https://github.com/cactus/go-camo"
  url "https://github.com/cactus/go-camo/archive/refs/tags/v2.7.4.tar.gz"
  sha256 "5f9122ce87e665a37e1644400b8564a600f6db39f0f55eec9d72aedb5c867c08"
  license "MIT"
  head "https://github.com/cactus/go-camo.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fcc880b127bce2b41328650cadcd1b5032c9f329f1480ae50b34be7312494e98"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.ServerVersion=#{version}"
    tags = "netgo,production"
    system "go", "build", *std_go_args(ldflags:, tags:), "./cmd/go-camo"
    system "go", "build", *std_go_args(ldflags:, tags:, output: bin/"url-tool"), "./cmd/url-tool"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/go-camo --version")
    assert_match version.to_s, shell_output("#{bin}/url-tool --version")

    port = free_port
    spawn bin/"go-camo", "--key", "somekey", "--listen", "127.0.0.1:#{port}", "--metrics"
    sleep 1
    assert_match "200 OK", shell_output("curl -sI http://localhost:#{port}/metrics")

    url = "https://golang.org/doc/gopher/frontpage.png"
    encoded = shell_output("#{bin}/url-tool -k 'test' encode -p 'https://img.example.org' '#{url}'").chomp
    decoded = shell_output("#{bin}/url-tool -k 'test' decode '#{encoded}'").chomp
    assert_equal url, decoded
  end
end
