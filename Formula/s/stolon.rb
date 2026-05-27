class Stolon < Formula
  desc "Cloud native PostgreSQL manager for high availability"
  homepage "https://github.com/sorintlab/stolon"
  url "https://github.com/sorintlab/stolon/archive/refs/tags/v0.17.0.tar.gz"
  sha256 "dad967378e7d0c5ee1df53a543e4f377af2c4fea37e59f3d518d67274cff5b34"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c43f6e97b04135164a0f694db76ec1ba9ca1afbd9326e680a1624b4a726cdb62"
  end

  depends_on "go" => :build
  depends_on "etcd" => :test
  depends_on "libpq"

  def install
    ldflags = "-s -w -X github.com/sorintlab/stolon/cmd.Version=#{version}"

    %w[
      stolonctl ./cmd/stolonctl
      stolon-keeper ./cmd/keeper
      stolon-sentinel ./cmd/sentinel
      stolon-proxy ./cmd/proxy
    ].each_slice(2) do |bin_name, src_path|
      system "go", "build", *std_go_args(ldflags:, output: bin/bin_name), src_path
    end
  end

  test do
    endpoint = "http://127.0.0.1:2379"
    pid = spawn "etcd", "--advertise-client-urls", endpoint, "--listen-client-urls", endpoint

    sleep 5

    assert_match "stolonctl version #{version}",
      shell_output("#{bin}/stolonctl version 2>&1")
    output = shell_output("#{bin}/stolonctl status --cluster-name test " \
                          "--store-backend etcdv3 --store-endpoints #{endpoint} 2>&1", 1)
    assert_match "nil cluster data: <nil>", output
    assert_match "stolon-keeper version #{version}",
      shell_output("#{bin}/stolon-keeper --version 2>&1")
    assert_match "stolon-sentinel version #{version}",
      shell_output("#{bin}/stolon-sentinel --version 2>&1")
    assert_match "stolon-proxy version #{version}",
      shell_output("#{bin}/stolon-proxy --version 2>&1")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
