class Tml < Formula
  desc "Tiny markup language for terminal output"
  homepage "https://github.com/liamg/tml"
  url "https://github.com/liamg/tml/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "45824c36e810c568365d7f04c69900a0ef1abb46644f94a054cfe2d160999320"
  license "Unlicense"
  head "https://github.com/liamg/tml.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18772555ed5d9f027c387ebdaf7fe748605447af15f7e84f1c1efc3694712290"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./tml"
  end

  test do
    output = pipe_output(bin/"tml", "<green>not red</green>", 0)
    assert_match "\e[0m\e[32mnot red\e[39m\e[0m", output
  end
end
