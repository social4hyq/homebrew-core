class Energy < Formula
  desc "CLI is used to initialize the Energy development environment tools"
  homepage "https://energye.github.io"
  url "https://github.com/energye/energy/archive/refs/tags/v2.5.6.tar.gz"
  sha256 "7dcc439e32a6b1723b7809175eb43856b7817899350bbf47f794b1103dfec69e"
  license "Apache-2.0"
  head "https://github.com/energye/energy.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f67e79f7d5b698ce6f244a25e90291b1d42b47be3062b1beda50128d6805d00a"
  end

  depends_on "go" => :build

  def install
    cd "cmd/energy" do
      system "go", "build", *std_go_args(ldflags: "-s -w")
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/energy cli")

    assert_match "https://energy.yanghy.cn", shell_output("#{bin}/energy env")
  end
end
