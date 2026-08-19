class Rad < Formula
  desc "Modern CLI scripts made easy"
  homepage "https://amterp.dev/rad/"
  url "https://github.com/amterp/rad/archive/refs/tags/v0.12.1.tar.gz"
  sha256 "db6d974c777017724272f34e6b1221746bb850c0859443b9bb9337e1dbcafc1d"
  license "Apache-2.0"
  head "https://github.com/amterp/rad.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "071750c53c98d513a765696673e981400c81ec2f7b755e4abd190866c5815e30"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    system "go", "build", *std_go_args(ldflags: "-s -w")
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"radls"), "./radls"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rad --version")

    (testpath/"test").write <<~SHELL
      #!/usr/bin/env rad

      args:
          times int = 1

      for _ in range(times):
          print("Hello, Homebrew!")
    SHELL
    chmod "+x", testpath/"test"

    assert_match "Hello, Homebrew!\nHello, Homebrew!", shell_output("#{testpath}/test 2")

    output_log = testpath/"output.log"
    pid = spawn bin/"radls", [:out, :err] => output_log.to_s
    sleep 2
    assert_match "Spinning up Rad LSP server", output_log.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
