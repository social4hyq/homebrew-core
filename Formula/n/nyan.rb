class Nyan < Formula
  desc "Colorizing `cat` command with syntax highlighting"
  homepage "https://github.com/toshimaru/nyan"
  url "https://github.com/toshimaru/nyan/archive/refs/tags/v1.2.6.tar.gz"
  sha256 "49b1245d87868f18b7577ab646d458fefc608f7eda27ad742648bdc69083a107"
  license "MIT"
  head "https://github.com/toshimaru/nyan.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7f2eb679a2db038f97cc6e2a988b62dae3c26f27fe54bf4786a3845a500dc5a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/toshimaru/nyan/cmd.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nyan --version")
    (testpath/"test.txt").write "nyan is a colourful cat."
    assert_match "nyan is a colourful cat.", shell_output("#{bin}/nyan test.txt")
  end
end
