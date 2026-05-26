class Mycorrhiza < Formula
  desc "Lightweight wiki engine with hierarchy support"
  homepage "https://mycorrhiza.wiki"
  url "https://github.com/bouncepaw/mycorrhiza/archive/refs/tags/v1.15.1.tar.gz"
  sha256 "92b56606cb2e8b1afe086b86e68355a7aa6202bf77514ca6f07b32f7f143f4c4"
  license "AGPL-3.0-only"
  head "https://github.com/bouncepaw/mycorrhiza.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a36c7802e6515333bbe9cd8df345f6f4d3f389cc6fbc951fae6866dec086d5b5"
  end

  depends_on "go" => :build

  def install
    system "make", "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  service do
    run [opt_bin/"mycorrhiza", var/"lib/mycorrhiza"]
    keep_alive true
    log_path var/"log/mycorrhiza.log"
    error_log_path var/"log/mycorrhiza.log"
  end

  test do
    port = free_port
    pid = spawn bin/"mycorrhiza", "-listen-addr", "127.0.0.1:#{port}", "."
    sleep 5

    # Create a hypha
    cmd = "curl -siF'text=This is a test hypha.' 127.0.0.1:#{port}/upload-text/test_hypha"
    assert_match "303 See Other", shell_output(cmd)

    # Verify that it got created
    cmd = "curl -s 127.0.0.1:#{port}/hypha/test_hypha"
    assert_match "This is a test hypha.", shell_output(cmd)
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
