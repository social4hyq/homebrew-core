class Orgalorg < Formula
  desc "Parallel SSH commands executioner and file synchronization tool"
  homepage "https://github.com/reconquest/orgalorg"
  url "https://github.com/reconquest/orgalorg/archive/refs/tags/1.3.1.tar.gz"
  sha256 "b9292ac6af1c492c82e4c77a707a026ad9674139f02d3fa25b797f65e3d69a2c"
  license "MIT"
  head "https://github.com/reconquest/orgalorg.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "922efa24115be4ea9bca9b8a8dfd1fa128c2b74fd6bffc370aec7e80cb546c1d"
  end

  depends_on "go" => :build

  def install
    system "go", "build", "-mod=mod", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orgalorg --version")
    assert_match "orgalorg - files synchronization on many hosts.", shell_output("#{bin}/orgalorg --help")

    ENV.delete "SSH_AUTH_SOCK"

    port = free_port
    output = shell_output("#{bin}/orgalorg -u tester --key '' --host=127.0.0.1:#{port} -C uptime 2>&1", 1)
    assert_match "connecting to cluster failed", output
    assert_match "dial tcp 127.0.0.1:#{port}: connect: connection refused", output
    assert_match "can't connect to address: [tester@127.0.0.1:#{port}]", output
  end
end
