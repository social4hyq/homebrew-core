class Webhook < Formula
  desc "Lightweight, configurable incoming webhook server"
  homepage "https://github.com/adnanh/webhook"
  url "https://github.com/adnanh/webhook/archive/refs/tags/2.8.3.tar.gz"
  sha256 "5bfb3d9efd75d33bfee81fb8dae935178f42689fe0165fc1f5c5a312a0162541"
  license "MIT"
  head "https://github.com/adnanh/webhook.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4973a6116acf132e2b00000cf491d75fcb5bfd725482a23be92a7b7e0f884a1b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"hooks.yaml").write <<~YAML
      - id: test
        execute-command: /bin/sh
        command-working-directory: "#{testpath}"
        pass-arguments-to-command:
        - source: string
          name: -c
        - source: string
          name: "pwd > out.txt"
    YAML

    port = free_port
    spawn bin/"webhook", "-hooks", "hooks.yaml", "-port", port.to_s
    sleep 1

    system "curl", "localhost:#{port}/hooks/test"
    sleep 1
    assert_equal testpath.to_s, (testpath/"out.txt").read.chomp
  end
end
