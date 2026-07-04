class Dblab < Formula
  desc "Database client every command-line junkie deserves"
  homepage "https://dblab.app/"
  url "https://github.com/danvergara/dblab/archive/refs/tags/v0.43.0.tar.gz"
  sha256 "d177e4aeff702f699f2b5c8ea37e75c3736582fa2c9956e2751e69ad6287e16f"
  license "MIT"
  head "https://github.com/danvergara/dblab.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "64a9d98b53eefd0d94ede3ac1cf563716f002ca03bef5434637ecd939ca73a23"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")

    generate_completions_from_executable(bin/"dblab", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dblab --version")

    output = shell_output("#{bin}/dblab --url mysql://user:password@tcp\\(localhost:3306\\)/db 2>&1", 1)
    assert_match "connect: connection refused", output
  end
end
