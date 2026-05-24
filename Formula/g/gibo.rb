class Gibo < Formula
  desc "Access GitHub's .gitignore boilerplates"
  homepage "https://github.com/simonwhitaker/gibo"
  url "https://github.com/simonwhitaker/gibo/archive/refs/tags/v3.0.22.tar.gz"
  sha256 "1c9432a3bd417709fee9a475b85dc0dbfa10e62676b54e8f3ea4d7c44f6e16b3"
  license "Unlicense"
  head "https://github.com/simonwhitaker/gibo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e8af70addd013797f259afa4d678538091f25394f38dda09206bc9c405f10dc"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/simonwhitaker/gibo/cmd.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"gibo", shell_parameter_format: :cobra)
  end

  test do
    system bin/"gibo", "update"
    assert_includes shell_output("#{bin}/gibo dump Python"), "Python.gitignore"

    assert_match version.to_s, shell_output("#{bin}/gibo version")
  end
end
