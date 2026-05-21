class FakeGcsServer < Formula
  desc "Emulator for Google Cloud Storage API"
  homepage "https://github.com/fsouza/fake-gcs-server"
  url "https://github.com/fsouza/fake-gcs-server/archive/refs/tags/v1.54.0.tar.gz"
  sha256 "12a874a6e3e8160a59c820e52ce1a5100c1c213720f0b033067269480d92cd6e"
  license "BSD-2-Clause"
  head "https://github.com/fsouza/fake-gcs-server.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24d774f116745bb6eb9632ca7e44c5dfcc40c05cfc8927c6e5a7a7616fb7978a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/fsouza/fake-gcs-server.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    port = free_port

    pid = spawn bin/"fake-gcs-server", "-host", "127.0.0.1", "-port", port.to_s,
                    "-backend", "memory", "-log-level", "warn"
    sleep 2

    begin
      output = shell_output("curl -k -s 'https://127.0.0.1:#{port}/storage/v1/b?project=test'")
      assert_equal "{\"kind\":\"storage#buckets\"}", output.strip

      # Create a bucket
      shell_output("curl -k -s -X POST 'https://127.0.0.1:#{port}/storage/v1/b?project=test' " \
                   "-H 'Content-Type: application/json' -d '{\"name\": \"test-bucket\"}'")

      # Verify bucket exists
      output = shell_output("curl -k -s 'https://127.0.0.1:#{port}/storage/v1/b?project=test'")
      assert_equal "test-bucket", JSON.parse(output)["items"][0]["id"]
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
