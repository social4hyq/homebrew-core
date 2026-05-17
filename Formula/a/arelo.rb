class Arelo < Formula
  desc "Simple auto reload (live reload) utility"
  homepage "https://github.com/makiuchi-d/arelo"
  url "https://github.com/makiuchi-d/arelo/archive/refs/tags/v1.15.4.tar.gz"
  sha256 "f687e04187145aa6ccaf68fc995f9e8297387a2f27871ccb132625e0635cf15d"
  license "MIT"
  head "https://github.com/makiuchi-d/arelo.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ba61d5c43594b2e753e8d4df6bc836e3851bdba1f0caff9be3c9a9f86a54ff49"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/arelo --version")

    (testpath/"test.sh").write <<~EOS
      #!/bin/sh
      echo "Hello, world!"
    EOS
    chmod 0755, testpath/"test.sh"

    logfile = testpath/"arelo.log"
    arelo_pid = spawn bin/"arelo", "--pattern", "test.sh", "--", "./test.sh", out: logfile.to_s

    sleep 1
    touch testpath/"test.sh"
    sleep 1

    assert_path_exists testpath/"test.sh"
    assert_match "Hello, world!", logfile.read
  ensure
    Process.kill("TERM", arelo_pid)
    Process.wait(arelo_pid)
  end
end
