class Gptscript < Formula
  desc "Develop LLM Apps in Natural Language"
  homepage "https://docs.gptscript.ai/"
  url "https://github.com/gptscript-ai/gptscript/archive/refs/tags/v0.9.9.tar.gz"
  sha256 "1f875ca3da55f1c2d697807a375dba517ad5f49a2b1115d22590b2bcd968548e"
  license "Apache-2.0"
  head "https://github.com/gptscript-ai/gptscript.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac9448a56ac92315776c6372e37d2b8c0296905d13b515abf16cae062345c744"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/gptscript-ai/gptscript/pkg/version.Tag=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)

    pkgshare.install "examples"
    generate_completions_from_executable(bin/"gptscript", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gptscript -v")
  end
end
