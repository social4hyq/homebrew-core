class Rad < Formula
  desc "Modern CLI scripts made easy"
  homepage "https://amterp.dev/rad/"
  url "https://github.com/amterp/rad/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "dd9e76d37f9f99f500c037ae1631c58b83d0ba60e96c587b90a7434de7dddb0c"
  license "Apache-2.0"
  head "https://github.com/amterp/rad.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca988b73179cd9cd7bbc1f4d61d5d9b4256bfb7464a717dd219a218dfc2c9737"
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
