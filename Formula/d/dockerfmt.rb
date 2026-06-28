class Dockerfmt < Formula
  desc "Dockerfile format and parser. a modern dockfmt"
  homepage "https://github.com/reteps/dockerfmt"
  url "https://github.com/reteps/dockerfmt/archive/refs/tags/v0.5.4.tar.gz"
  sha256 "feceb63f17513d8310efbe81c660bf48f6a3bd8040ab00a45dc4c9fbf591033f"
  license "MIT"
  head "https://github.com/reteps/dockerfmt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07f0892327547ada4083dd9152e3e2b844b25da9a32ad0559ab972c94c2f3f99"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/reteps/dockerfmt/cmd.Version=#{version}")
    generate_completions_from_executable(bin/"dockerfmt", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dockerfmt version")

    (testpath/"Dockerfile").write <<~DOCKERFILE
      FROM alpine:latest
    DOCKERFILE

    output = shell_output("#{bin}/dockerfmt --check Dockerfile 2>&1", 1)
    assert_match "Dockerfile is not formatted", output
  end
end
