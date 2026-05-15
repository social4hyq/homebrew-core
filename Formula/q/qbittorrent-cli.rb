class QbittorrentCli < Formula
  desc "Command-line interface for qBittorrent written in Go"
  homepage "https://github.com/ludviglundgren/qbittorrent-cli"
  url "https://github.com/ludviglundgren/qbittorrent-cli/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "66b082b4b1653aae785b0f12bc00d7ac4dd8f17028d99e3feafac8aded931957"
  license "MIT"
  head "https://github.com/ludviglundgren/qbittorrent-cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5017a5b68886fd90bb9a9ac51b447f7c7be0a567e59880b8f64a952532bf6d39"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"qbt"), "./cmd/qbt"

    generate_completions_from_executable(bin/"qbt", shell_parameter_format: :cobra)
  end

  test do
    port = free_port
    (testpath/"config.qbt.toml").write <<~TOML
      [qbittorrent]
      addr = "http://127.0.0.1:#{port}"
    TOML

    output = shell_output("#{bin}/qbt app version --config #{testpath}/config.qbt.toml 2>&1", 1)
    assert_match "could not get app version", output

    assert_match version.to_s, shell_output("#{bin}/qbt version")
  end
end
