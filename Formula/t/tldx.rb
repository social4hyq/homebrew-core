class Tldx < Formula
  desc "Domain Availability Research Tool"
  homepage "https://brandonyoung.dev/blog/introducing-tldx/"
  url "https://github.com/brandonyoungdev/tldx/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "78cbbe9ee16ae9325443ad585cd9268015c36d804e108e70735e1424980277bd"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f22dca81df64be21db5526c3d553efb31b76c16ed6ce75875c6f17c8cdd7edf3"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/brandonyoungdev/tldx/cmd.Version=#{version}")
    generate_completions_from_executable(bin/"tldx", shell_parameter_format: :cobra)
  end

  test do
    assert_match "brew.sh is not available", shell_output("#{bin}/tldx brew --tlds sh")

    assert_match version.to_s, shell_output("#{bin}/tldx --version")
  end
end
