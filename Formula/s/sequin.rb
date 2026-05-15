class Sequin < Formula
  desc "Human-readable ANSI sequences"
  homepage "https://github.com/charmbracelet/sequin"
  url "https://github.com/charmbracelet/sequin/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "52f4d704a6e019df05dfc0ee3808fdf6c7d3245dcaa6262db8ca33c9de303da9"
  license "MIT"
  head "https://github.com/charmbracelet/sequin.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ea1edc632db6a0deeb1d3d024f4d14966759648545debc824b24aba0435d567"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sequin -v")

    assert_match "CSI m: Reset style", pipe_output(bin/"sequin", "\x1b[m")
  end
end
