class Appwrite < Formula
  desc "Command-line tool for Appwrite"
  homepage "https://appwrite.io"
  url "https://github.com/appwrite/sdk-for-cli/archive/refs/tags/27.3.0.tar.gz"
  sha256 "363950af2290b149d5ea376e1f7dd202d61a3a38f3b536bb2fcefd515a1c9a57"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e785417cb4ed1f52a6ce737b9af4cac009cd2aa260244e057f492989d1da5549"
  end

  depends_on "go" => :build

  def install
    # https://github.com/appwrite/sdk-for-cli/blob/4399a3321898f40cf982acbd4859d506c9d4d9f4/.goreleaser.yaml#L19-L22
    system "go", "mod", "tidy"
    system "go", "build", *std_go_args(ldflags: "-X github.com/appwrite/sdk-for-cli/internal/app.Version=#{version}")

    generate_completions_from_executable(bin/"appwrite", "completion")
  end

  test do
    output = shell_output("#{bin}/appwrite client --endpoint http://localhost/v1 2>&1", 1)
    assert_match "Error: invalid endpoint", output

    assert_match version.to_s, shell_output("#{bin}/appwrite --version")
  end
end
