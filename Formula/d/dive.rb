class Dive < Formula
  desc "Tool for exploring each layer in a docker image"
  homepage "https://github.com/wagoodman/dive"
  url "https://github.com/wagoodman/dive/archive/refs/tags/v0.13.1.tar.gz"
  sha256 "2a9666e9c3fddd5e2e5bad81dccda520b8102e7cea34e2888f264b4eb0506852"
  license "MIT"
  head "https://github.com/wagoodman/dive.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d384d104560a65957ca056e6a41af74d9372f03e0a1c206f17c820bdb37cfd1"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")

    generate_completions_from_executable(bin/"dive", shell_parameter_format: :cobra)
  end

  test do
    (testpath/"Dockerfile").write <<~DOCKERFILE
      FROM alpine
      ENV test=homebrew-core
      RUN echo "hello"
    DOCKERFILE

    assert_match "dive #{version}", shell_output("#{bin}/dive version")
    assert_match "Building image", shell_output("CI=true #{bin}/dive build .", 1)
  end
end
