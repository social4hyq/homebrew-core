class HubTool < Formula
  desc "Docker Hub experimental CLI tool"
  homepage "https://github.com/docker/hub-tool"
  url "https://github.com/docker/hub-tool/archive/refs/tags/v04.6.tar.gz"
  sha256 "e033e027c4b6dc360abf530a00b3ac0caec5ab17788c015336eb59a5e854e7d1"
  license "Apache-2.0"
  head "https://github.com/docker/hub-tool.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b72a091533e83360eb951260b772a788a440f322470c10f0f365663efd1daaa1"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/docker/hub-tool/internal.Version=#{version}
      -X github.com/docker/hub-tool/internal.GitCommit=#{tap.user}
    ]

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hub-tool version")
    output = shell_output("#{bin}/hub-tool token 2>&1", 1)
    assert_match "You need to be logged in to Docker Hub to use this tool", output
  end
end
